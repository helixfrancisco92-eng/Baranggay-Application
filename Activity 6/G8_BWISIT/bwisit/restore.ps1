<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: restore.ps1
Purpose: Restore PostgreSQL custom dump archive into isolated test database
Target: canteen_db_activity6_restore_test
Utility: pg_restore
==============================================================================
#>
[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$AdminUser = "postgres",
    [string]$OriginalDb = "canteen_db",
    [string]$RestoreDb = "canteen_db_activity6_restore_test",
    [string]$BackupFile = "",
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$logsDir = Join-Path $workspaceRoot "logs"
$backupDir = Join-Path $workspaceRoot "backups"

if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }

# CRITICAL BOUNDARY ENFORCEMENT
if ($RestoreDb.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    throw "FATAL SECURITY ERROR: Restoration directly into original database '$OriginalDb' is strictly forbidden! Choose a separate test database."
}

# Locate backup file
if ([string]::IsNullOrWhiteSpace($BackupFile)) {
    $latest = Get-ChildItem -Path $backupDir -Filter "*.dump" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $BackupFile = $latest.FullName
    } else {
        throw "No .dump file found in '$backupDir'. Provide path via -BackupFile."
    }
}

if (-not (Test-Path $BackupFile)) {
    throw "Backup archive file '$BackupFile' was not found."
}

# Locate pg_restore and psql
$pgRestoreCmd = Get-Command "pg_restore" -ErrorAction SilentlyContinue
$psqlCmd = Get-Command "psql" -ErrorAction SilentlyContinue

$pgRestorePath = if ($pgRestoreCmd) { $pgRestoreCmd.Source } else { Join-Path $PsqlPath "pg_restore.exe" }
$psqlPathExe = if ($psqlCmd) { $psqlCmd.Source } else { Join-Path $PsqlPath "psql.exe" }

if (-not (Test-Path $pgRestorePath)) { throw "pg_restore.exe not found at '$pgRestorePath'." }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - Database Restoration into Isolated Environment" -ForegroundColor Cyan
Write-Host " Source Backup Archive : $BackupFile" -ForegroundColor Cyan
Write-Host " Destination Database  : $RestoreDb" -ForegroundColor Cyan
Write-Host " Host / Port           : ${HostName}:${Port} | User: $AdminUser" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# Acquire password securely
$securePw = $null
if (-not $env:PGPASSWORD) {
    $securePw = Read-Host "Enter password for administrative user '$AdminUser'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

$restoreLog = Join-Path $logsDir "restore-execution.log"

try {
    # Check if destination has existing public tables
    $tableQuery = "SELECT count(*) FROM information_schema.tables WHERE table_schema='public';"
    $existingCount = (& $psqlPathExe -h $HostName -p $Port -U $AdminUser -d $RestoreDb -tAc $tableQuery).Trim()

    if ([int]$existingCount -gt 0) {
        Write-Warning "Destination database '$RestoreDb' already contains $existingCount public tables."
        $confirm = Read-Host "Proceed with restoration anyway? (y/n)"
        if ($confirm -notmatch '^[Yy]') {
            Write-Host "Restoration aborted by operator."
            return
        }
    }

    Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Restoring archive using pg_restore..." -ForegroundColor Yellow
    
    # Run pg_restore without suppressing errors blindly
    & $pgRestorePath -h $HostName -p $Port -U $AdminUser -v -d $RestoreDb $BackupFile 2>&1 | Set-Content -Path $restoreLog -Encoding utf8
    $exitCode = $LASTEXITCODE

    Write-Host "------------------------------------------------------------------------------"
    Write-Host " RESTORATION EXECUTION SUMMARY"
    Write-Host "------------------------------------------------------------------------------"
    Write-Host " Exit Code       : $exitCode"
    Write-Host " Log Destination : $restoreLog"

    if ($exitCode -eq 0) {
        Write-Host "[PASS] Database restored with ZERO errors." -ForegroundColor Green
    } elseif ($exitCode -eq 1) {
        Write-Host "[NOTICE] pg_restore finished with minor warnings (Exit Code 1)." -ForegroundColor Yellow
        Write-Host "Review $restoreLog for detailed ownership/privilege notices."
    } else {
        Write-Host "[ERROR] pg_restore failed with exit code $exitCode." -ForegroundColor Red
        throw "Restoration failed. See log at $restoreLog."
    }

    Write-Host "==============================================================================" -ForegroundColor Cyan
    Write-Host " Next step: Execute 'verify-restore.sql' and 'verify-access-control.sql' via psql." -ForegroundColor Cyan
    Write-Host "==============================================================================" -ForegroundColor Cyan
}
catch {
    Write-Error "Restore operation failed: $_"
    exit 1
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

