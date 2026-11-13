<#
==============================================================================
PUP-SPOT (Group 5) — Automated Database Backup Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Target Project: PUP-SPOT Lost and Found System
Database Engine: PostgreSQL 18.0 / 16+
Target Database: grp05_lostandfounddb
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$Database = "grp05_lostandfounddb",
    [string]$Username = "lf_admin_user",
    [string]$BackupDirectory = "C:\Users\Lenovo\Downloads\backups"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " PUP-SPOT Database Backup Utility (PostgreSQL pg_dump -Fc)       " -ForegroundColor Cyan
Write-Host " Course: COMP 018 Database Administration (Activity 6)           " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Verify PostgreSQL client utilities
Write-Host "[1/6] Verifying pg_dump client utility..." -ForegroundColor Yellow
$pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
if (-not $pgDumpCmd) {
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin"
    )
    foreach ($p in $commonPgPaths) {
        if (Test-Path "$p\pg_dump.exe") {
            $env:PATH = "$p;$env:PATH"
            $pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $pgDumpCmd) {
    Write-Error "[FATAL] pg_dump.exe was not found in PATH or standard PostgreSQL installations."
    exit 1
}

$pgVersion = & pg_dump --version
Write-Host "      Detected Utility: $pgVersion" -ForegroundColor Green

# 2. Check Database Reachability
Write-Host "[2/6] Testing database server connectivity..." -ForegroundColor Yellow
$psqlCmd = Get-Command psql.exe -ErrorAction SilentlyContinue
if ($psqlCmd) {
    if (-not $env:PGPASSWORD) {
        Write-Host "      Notice: PGPASSWORD environment variable is not set. Using Activity 4 credentials..." -ForegroundColor DarkGray
        $env:PGPASSWORD = "AdminPassword123"
    }
    $connTest = & psql -U $Username -h $HostName -p $Port -d $Database -c "SELECT 1;" 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "[WARNING] Direct pre-check query returned non-zero code. Output: $connTest"
    } else {
        Write-Host "      Database connectivity verified successfully." -ForegroundColor Green
    }
}

# 3. Prepare Backup Destination
Write-Host "[3/6] Preparing backup destination directory..." -ForegroundColor Yellow
if (-not (Test-Path $BackupDirectory)) {
    New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
}
$resolvedBackupDir = (Resolve-Path $BackupDirectory).Path
Write-Host "      Storage Root: $resolvedBackupDir" -ForegroundColor Green

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFilename = "${Database}_backup_${timestamp}.dump"
$backupFilePath = Join-Path $resolvedBackupDir $backupFilename

Write-Host "      Target File: $backupFilename" -ForegroundColor Green

# 4. Execute pg_dump with Custom Format (-Fc)
Write-Host "[4/6] Executing logical backup (pg_dump -Fc)..." -ForegroundColor Yellow
$startTime = Get-Date

# Execute command safely without echoing credentials
& pg_dump -U $Username -h $HostName -p $Port -Fc -d $Database -f $backupFilePath
$exitCode = $LASTEXITCODE
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

# 5. Validate Output File Integrity
Write-Host "[5/6] Validating backup archive integrity..." -ForegroundColor Yellow
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

$fileHash = (Get-FileHash -Path $backupFilePath -Algorithm SHA256).Hash

Write-Host "=================================================================" -ForegroundColor Green
Write-Host " BACKUP GENERATED SUCCESSFULLY                                   " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " Target Database : $Database"
Write-Host " Archive Path    : $backupFilePath"
Write-Host " File Size       : $($fileItem.Length) bytes ($([math]::Round($fileItem.Length/1KB, 2)) KB)"
Write-Host " SHA-256 Hash    : $fileHash"
Write-Host " Duration        : $([math]::Round($duration, 2)) seconds"
Write-Host " Timestamp       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "=================================================================" -ForegroundColor Green

# 6. Append to execution log if available
$logFile = Join-Path $PSScriptRoot "..\reports\execution-log.md"
if (Test-Path $logFile) {
    $logEntry = "| $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') | Logical Backup (pg_dump -Fc) | $Database | pg_dump -U $Username -h $HostName -p $Port -Fc -d $Database -f $backupFilename | Exit Code: $exitCode, Size: $($fileItem.Length) bytes, SHA256: $fileHash | $exitCode | None | evidence/backup_verification.txt | COMPLETED AND VERIFIED |`n"
    Add-Content -Path $logFile -Value $logEntry
}

