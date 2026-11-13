<#
==============================================================================
CampusSafe (Group 7) — PostgreSQL Automated Backup Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Evaluating Group: Group 12
Target Database: grp07_campussafedb
Backup Format: PostgreSQL Custom Compressed Archive (-Fc)
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$HostName = $env:DB_HOST,
    [string]$Port = $env:DB_PORT,
    [string]$Database = $env:DB_NAME,
    [string]$Username = $env:DB_USER,
    [string]$BackupDirectory = $env:BACKUP_DIR
)

# Apply Defaults
if (-not $HostName) { $HostName = "localhost" }
if (-not $Port) { $Port = "5432" }
if (-not $Database) { $Database = "grp07_campussafedb" }
if (-not $Username) { $Username = "campussafe_backup" }
if (-not $BackupDirectory) { $BackupDirectory = Join-Path $PSScriptRoot "..\backups" }

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " CampusSafe (Group 7) Database Backup Utility (PowerShell)       " -ForegroundColor Cyan
Write-Host " Target Database: $Database                                      " -ForegroundColor Cyan
Write-Host " Backup Operator: $Username                                      " -ForegroundColor Cyan
Write-Host " Host / Port:     ${HostName}:${Port}                            " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Locate and Verify pg_dump Utility
Write-Host "[1/5] Verifying pg_dump client utility..." -ForegroundColor Yellow
$pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
if (-not $pgDumpCmd) {
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin",
        "C:\Program Files\PostgreSQL\15\bin",
        "C:\Program Files\PostgreSQL\14\bin"
    )
    foreach ($p in $commonPgPaths) {
        if (Test-Path (Join-Path $p "pg_dump.exe")) {
            $env:PATH = "$p;$env:PATH"
            $pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $pgDumpCmd) {
    Write-Error "[-] ERROR: pg_dump.exe was not found in PATH or standard Program Files locations."
    exit 1
}
Write-Host "    Found pg_dump at: $($pgDumpCmd.Source)" -ForegroundColor Green

# 2. Ensure Destination Directory Exists
if (-not (Test-Path $BackupDirectory)) {
    Write-Host "[*] Creating backup destination directory: $BackupDirectory" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFile = Join-Path $BackupDirectory "${Database}_activity6.dump"
$timestampedFile = Join-Path $BackupDirectory "${Database}_${timestamp}.dump"
$manifestFile = Join-Path $BackupDirectory "${Database}_manifest_${timestamp}.txt"

# 3. Check Network Connectivity to Port
Write-Host "[2/5] Testing TCP connection to ${HostName}:${Port}..." -ForegroundColor Yellow
$tcpTest = Test-NetConnection -ComputerName $HostName -Port ([int]$Port) -WarningAction SilentlyContinue
if (-not $tcpTest.TcpTestSucceeded) {
    Write-Warning "[-] WARNING: TCP port ${Port} on '${HostName}' is unreachable. Verify PostgreSQL service is running."
} else {
    Write-Host "    PostgreSQL service port is listening." -ForegroundColor Green
}

# 4. Execute Custom Archive Dump
Write-Host "[3/5] Executing pg_dump custom archive export (-Fc)..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$dumpArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-Fc",
    "-d", $Database,
    "-f", $backupFile
)

try {
    & pg_dump.exe @dumpArgs
    if ($LASTEXITCODE -ne 0) {
        throw "pg_dump.exe exited with non-zero error code: $LASTEXITCODE"
    }
} catch {
    Write-Error "[-] FATAL: Database backup failed: $_"
    exit 1
}

$sw.Stop()
$durationSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)

# Copy to timestamped archive
Copy-Item -Path $backupFile -Destination $timestampedFile -Force

# 5. Compute File Size and Cryptographic SHA-256 Checksum
Write-Host "[4/5] Computing file size and SHA-256 checksum..." -ForegroundColor Yellow
$fileItem = Get-Item $backupFile
$fileSize = $fileItem.Length
$fileHash = (Get-FileHash -Path $backupFile -Algorithm SHA256).Hash

# 6. Generate Manifest Record
$manifestContent = @"
=================================================================
CampusSafe (Group 7) — Activity 6 Backup Manifest Record
=================================================================
Target Database:     $Database
Backup Operator:     $Username
Host:Port:           ${HostName}:${Port}
Backup File:         $($fileItem.Name)
Timestamped File:    $([System.IO.Path]::GetFileName($timestampedFile))
Backup Format:       PostgreSQL Custom Archive (-Fc, zlib compressed)
File Size (bytes):   $fileSize
SHA-256 Checksum:    $fileHash
Creation Date (UTC): $((Get-Date).ToUniversalTime().ToString("yyyy-MM-dd HH:mm:ss UTC"))
Duration (seconds):  $durationSec
Exit Status:         SUCCESS (Code 0)
=================================================================
"@

Set-Content -Path $manifestFile -Value $manifestContent -Encoding UTF8

Write-Host "[5/5] Backup completed successfully in ${durationSec}s." -ForegroundColor Green
Write-Host ""
Write-Host $manifestContent -ForegroundColor White
Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "[+] SUCCESS: Backup stored at: $backupFile" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

