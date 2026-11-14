# ==============================================================================
# Script: restore.ps1
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Execute PostgreSQL Database Restoration into Isolated Test Database
# OS / Environment: Windows PowerShell
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$RestoreDb = "boardtrack_db_activity6_restore_test",

    [Parameter(Mandatory=$false)]
    [string]$OriginalDb = "boardtrack_db",

    [Parameter(Mandatory=$false)]
    [string]$DumpPath = "C:\db-backups\boardtrack\boardtrack_db_activity6.dump",

    [Parameter(Mandatory=$false)]
    [string]$AdminUser = "postgres",

    [Parameter(Mandatory=$false)]
    [string]$HostName = "localhost",

    [Parameter(Mandatory=$false)]
    [int]$Port = 5432,

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "$PSScriptRoot\..\logs\restore.log"
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  BoardTrack Database Restoration — COMP 018 Activity 6" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Timestamp      : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Target Host    : ${HostName}:${Port}"
Write-Host "Destination DB : $RestoreDb"
Write-Host "Live DB Guard  : $OriginalDb"
Write-Host "Admin User     : $AdminUser"
Write-Host "Source Archive : $DumpPath"
Write-Host "===================================================================="

# CRITICAL SAFETY CHECK: NEVER RESTORE OVER LIVE DATABASE
if ($RestoreDb.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    Write-Host "[FATAL ERROR] Target database equals live database ($OriginalDb)!" -ForegroundColor Red
    Write-Host "[FATAL ERROR] Restoration aborted to protect original records." -ForegroundColor Red
    exit 1
}

# Verify source backup exists
if (-not (Test-Path $DumpPath)) {
    Write-Host "[ERROR] Source dump archive not found at: $DumpPath" -ForegroundColor Red
    exit 1
}

# Ensure logs dir exists
$logDir = Split-Path -Path $LogFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$pgRestoreCmd = "pg_restore"
$psqlCmd = "psql"

if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe") {
        $pgRestoreCmd = "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe"
        $psqlCmd = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
    }
}

# Confirm destination exists
$dbCheckSql = "SELECT 1 FROM pg_database WHERE datname = '$RestoreDb';"
$exists = & $psqlCmd -h $HostName -p $Port -U $AdminUser -tAc $dbCheckSql 2>&1
if ($exists -notmatch "1") {
    Write-Host "[ERROR] Target restoration database '$RestoreDb' does not exist." -ForegroundColor Red
    Write-Host "[INFO] Please run create-restore-db.ps1 first." -ForegroundColor Yellow
    exit 1
}

Write-Host "[INFO] Commencing restoration via pg_restore..." -ForegroundColor Yellow
$startTime = Get-Date

# Execute pg_restore without blind error suppression (no --no-owner or --no-acl unless analyzed)
& $pgRestoreCmd -h $HostName -p $Port -U $AdminUser -d $RestoreDb -v $DumpPath 2>&1 | Tee-Object -FilePath $LogFile
$restoreExitCode = $LASTEXITCODE

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host ""
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  RESTORATION EXECUTION AUDIT SUMMARY" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Destination DB  : $RestoreDb"
Write-Host "Execution Time  : $duration seconds"
Write-Host "Execution Log   : $LogFile"

# PostgreSQL pg_restore returns exit code 1 if warnings occurred (e.g. extension or role notices)
if ($restoreExitCode -eq 0) {
    Write-Host "[SUCCESS] pg_restore completed with zero warnings/errors (Exit Code 0)." -ForegroundColor Green
} elseif ($restoreExitCode -eq 1) {
    Write-Host "[NOTICE] pg_restore finished with non-fatal warnings (Exit Code 1)." -ForegroundColor Yellow
    Write-Host "[INFO] Review $LogFile for specific notices (e.g. role/ownership/extension warnings)." -ForegroundColor Yellow
} else {
    Write-Host "[ERROR] pg_restore failed with critical error code $restoreExitCode." -ForegroundColor Red
    exit $restoreExitCode
}

Write-Host ""
Write-Host "[NEXT STEP] Execute SQL verification suite:" -ForegroundColor Cyan
Write-Host "  psql -h $HostName -p $Port -U $AdminUser -d $RestoreDb -f ..\scripts\verify-database.sql" -ForegroundColor Cyan
Write-Host "===================================================================="

