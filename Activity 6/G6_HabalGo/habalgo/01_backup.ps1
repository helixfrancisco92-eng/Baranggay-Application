<#
==============================================================================
HabalGo (Group 6) — Automated PostgreSQL Backup Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Platform: PostgreSQL 15+ / Target Database: grp00_habalgodb
Backup Format: Custom Compressed Archive (-Fc)
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

# Apply Defaults if not specified in parameters or environment
if (-not $HostName) { $HostName = "localhost" }
if (-not $Port) { $Port = "5432" }
if (-not $Database) { $Database = "grp00_habalgodb" }
if (-not $Username) { $Username = "postgres" }
if (-not $BackupDirectory) { $BackupDirectory = Join-Path $PSScriptRoot "..\backups" }

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " HabalGo Database Backup Utility (PostgreSQL pg_dump -Fc)        " -ForegroundColor Cyan
Write-Host " Target Database: $Database                                      " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Locate and Verify pg_dump Utility
Write-Host "[1/6] Verifying pg_dump client utility..." -ForegroundColor Yellow
$pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
if (-not $pgDumpCmd) {
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin",
        "C:\Program Files\PostgreSQL\15\bin"
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
    Write-Error "[FATAL] pg_dump.exe was not found in PATH or standard PostgreSQL paths."
    exit 1
}

$pgVersion = & pg_dump --version
Write-Host "      Detected Utility: $pgVersion" -ForegroundColor Green

# 2. Prepare Backup Directory
Write-Host "[2/6] Preparing backup destination directory..." -ForegroundColor Yellow
if (-not (Test-Path $BackupDirectory)) {
    New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
}
$resolvedBackupDir = (Resolve-Path $BackupDirectory).Path
Write-Host "      Backup Root: $resolvedBackupDir" -ForegroundColor Green

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFilename = "${Database}_activity6_${timestamp}.dump"
$backupFilePath = Join-Path $resolvedBackupDir $backupFilename
$checksumFilePath = "${backupFilePath}.sha256"

Write-Host "      Target File: $backupFilename" -ForegroundColor Green

# 3. Secure Credential Check
if (-not $env:PGPASSWORD) {
    Write-Host "      Notice: PGPASSWORD environment variable is not set. If authentication is prompted, please supply the password." -ForegroundColor DarkGray
}

# 4. Execute pg_dump with Custom Format (-Fc)
Write-Host "[3/6] Executing pg_dump (-Fc) against database '$Database'..." -ForegroundColor Yellow
$startTime = Get-Date

& pg_dump -U $Username -h $HostName -p $Port -Fc -d $Database -f $backupFilePath
$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# 5. Validate Output File Integrity
Write-Host "[4/6] Validating generated backup file integrity..." -ForegroundColor Yellow
if ($exitCode -ne 0 -or (-not (Test-Path $backupFilePath))) {
    Write-Error "[FAILED] pg_dump execution failed with exit code: $exitCode"
    exit 1
}

$fileItem = Get-Item $backupFilePath
if ($fileItem.Length -eq 0) {
    Write-Error "[FAILED] Generated backup file is empty (0 bytes). Backup aborted."
    Remove-Item $backupFilePath -Force
    exit 1
}

# 6. Generate SHA-256 Checksum
Write-Host "[5/6] Computing SHA-256 cryptographic checksum..." -ForegroundColor Yellow
$fileHash = (Get-FileHash -Path $backupFilePath -Algorithm SHA256).Hash
"$fileHash  $backupFilename" | Out-File -FilePath $checksumFilePath -Encoding ascii

# 7. Display Completion Manifest
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " BACKUP COMPLETED SUCCESSFULLY                                   " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " Database Name      : $Database"
Write-Host " Host / Port        : ${HostName}:${Port}"
Write-Host " Output File Path   : $backupFilePath"
Write-Host " File Size (Bytes)  : $($fileItem.Length) bytes ($([math]::Round($fileItem.Length/1KB, 2)) KB)"
Write-Host " SHA-256 Checksum   : $fileHash"
Write-Host " Checksum Manifest  : $checksumFilePath"
Write-Host " Execution Duration : $([math]::Round($duration, 2)) seconds"
Write-Host " Timestamp          : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host " Status             : SUCCESS (Exit Code: $exitCode)"
Write-Host "=================================================================" -ForegroundColor Green

