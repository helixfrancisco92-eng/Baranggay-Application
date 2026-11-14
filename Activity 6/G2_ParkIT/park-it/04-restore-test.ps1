<#
.SYNOPSIS
    COMP 018 — Database Administration (Activity 6: Part C)
    Script: 04-restore-test.ps1 (Windows Native PowerShell Companion)
    Purpose: Isolated Test Restoration of Park-It Database Backup
    Platform: PostgreSQL 18.6 | Safety: Restores ONLY into separate test database
#>

[CmdletBinding()]
param(
    [string]$BackupFile = ""
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "  PARK-IT DATABASE MANAGEMENT SYSTEM — ISOLATED RESTORATION TEST" -ForegroundColor Cyan
Write-Host "  COMP 018 Database Administration (Activity 6: Part C - Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Blue

# Check binaries
$standardPath = "C:\Program Files\PostgreSQL\18\bin"
if (Test-Path $standardPath) { $env:PATH = "$env:PATH;$standardPath" }

foreach ($bin in @("pg_restore.exe", "createdb.exe", "psql.exe")) {
    if (-not (Get-Command $bin -ErrorAction SilentlyContinue)) {
        Write-Error "[ERROR] Required PostgreSQL utility '$bin' was not found in PATH."
        exit 1
    }
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupDir = Join-Path $scriptDir "..\backups"

# Locate backup
if ([string]::IsNullOrWhiteSpace($BackupFile)) {
    $canonical = Join-Path $backupDir "grp_parkitdb_activity6.dump"
    if (Test-Path $canonical) {
        $BackupFile = $canonical
    } elseif (Test-Path $backupDir) {
        $latest = Get-ChildItem -Path $backupDir -Filter "*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) { $BackupFile = $latest.FullName }
    }
}

if ([string]::IsNullOrWhiteSpace($BackupFile)) {
    $BackupFile = Read-Host "Enter path to backup archive (.dump)"
}

if (-not (Test-Path $BackupFile) -or (Get-Item $BackupFile).Length -eq 0) {
    Write-Error "[ERROR] Specified backup file does not exist or is empty: $BackupFile"
    exit 1
}

# Pre-restore inspect
Write-Host "`n--- Pre-Restoration Archive Check ---" -ForegroundColor Yellow
& pg_restore.exe --list $BackupFile | Out-Null
if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Archive verification failed. Dump file may be corrupt."
    exit 1
}
Write-Host "[OK] Archive successfully verified via pg_restore --list." -ForegroundColor Green

# Configuration Prompts
Write-Host "`n--- Restoration Target Configuration ---" -ForegroundColor Yellow
$dbHost = Read-Host "Enter Database Host [localhost]"
if ([string]::IsNullOrWhiteSpace($dbHost)) { $dbHost = "localhost" }

$dbPort = Read-Host "Enter Database Port [5432]"
if ([string]::IsNullOrWhiteSpace($dbPort)) { $dbPort = "5432" }

$dbAdmin = Read-Host "Enter Administrative Username [postgres]"
if ([string]::IsNullOrWhiteSpace($dbAdmin)) { $dbAdmin = "postgres" }

$testDb = Read-Host "Enter Target Test Database Name [grp_parkitdb_restore_test]"
if ([string]::IsNullOrWhiteSpace($testDb)) { $testDb = "grp_parkitdb_restore_test" }

# SAFETY GUARD: NEVER OVERWRITE ORIGINAL DATABASE
if ($testDb -eq "grp_parkitdb") {
    Write-Host "`n================================================================" -ForegroundColor Red
    Write-Host "[CRITICAL SECURITY HALT] DANGEROUS TARGET DETECTED!" -ForegroundColor Red
    Write-Host "Target database cannot be the original database 'grp_parkitdb'!" -ForegroundColor Red
    Write-Host "Restoring directly over production risks catastrophic data loss." -ForegroundColor Red
    Write-Host "================================================================" -ForegroundColor Red
    exit 1
}

# Secure password handling
if (-not $env:PGPASSWORD) {
    Write-Host "Enter PostgreSQL password for user '$dbAdmin':" -ForegroundColor Yellow
    $securePass = Read-Host -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# Check if target db already exists
Write-Host "`n--- Checking Target Database Status ---" -ForegroundColor Yellow
$dbCheckQuery = "SELECT 1 FROM pg_database WHERE datname = '$testDb'"
$exists = & psql.exe -h $dbHost -p $dbPort -U $dbAdmin -tAc $dbCheckQuery 2>$null

if ($exists -eq "1") {
    Write-Host "[WARNING] Target test database '$testDb' already exists." -ForegroundColor Yellow
    Write-Host "To prevent accidental data loss, existing databases are never automatically dropped."
    $useAlt = Read-Host "Do you want to use a timestamped database name? (Y/n)"
    if ([string]::IsNullOrWhiteSpace($useAlt) -or $useAlt -match "^[Yy]") {
        $testDb = "${testDb}_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Write-Host "Using new target database name: $testDb" -ForegroundColor Cyan
        & createdb.exe -h $dbHost -p $dbPort -U $dbAdmin $testDb
        Write-Host "[OK] Created database: $testDb" -ForegroundColor Green
    }
} else {
    Write-Host "Creating clean test database: $testDb..." -ForegroundColor Cyan
    & createdb.exe -h $dbHost -p $dbPort -U $dbAdmin $testDb
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[ERROR] Failed to create database '$testDb'."
        exit 1
    }
    Write-Host "[OK] Created database: $testDb" -ForegroundColor Green
}

# Execute pg_restore
Write-Host "`n--- Commencing Database Restoration via pg_restore ---" -ForegroundColor Blue
Write-Host "Source Archive : $BackupFile" -ForegroundColor Cyan
Write-Host "Destination DB : $testDb" -ForegroundColor Cyan
Write-Host "Admin User     : $dbAdmin" -ForegroundColor Cyan

$sessionLog = Join-Path $backupDir "restore_${testDb}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

& pg_restore.exe -h $dbHost -p $dbPort -U $dbAdmin -d $testDb -v $BackupFile > $sessionLog 2>&1
$restoreExit = $LASTEXITCODE
$endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

$mainLog = Join-Path $backupDir "restore_test.log"
"[$endTime] RESTORE DRILL: Archive=$BackupFile TargetDB=$testDb ExitCode=$restoreExit Start=$startTime End=$endTime" | Out-File -Append -FilePath $mainLog

if ($restoreExit -eq 0) {
    Write-Host "`n[SUCCESS] Restoration completed cleanly with exit code 0." -ForegroundColor Green
} elseif ($restoreExit -eq 1) {
    Write-Host "`n[COMPLETED WITH WARNINGS] Restoration completed with non-fatal warnings (exit code 1)." -ForegroundColor Yellow
    Write-Host "Review log for details: $sessionLog" -ForegroundColor Yellow
} else {
    Write-Host "`n[ERROR] Restoration failed with exit code $restoreExit." -ForegroundColor Red
    exit $restoreExit
}

Write-Host "`n================================================================" -ForegroundColor Green
Write-Host "  ISOLATED RESTORATION TEST SUMMARY                             " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Restored Database : $testDb" -ForegroundColor Cyan
Write-Host "Archive Source    : $BackupFile" -ForegroundColor Cyan
Write-Host "Restoration Log   : $sessionLog" -ForegroundColor Cyan
Write-Host "Status            : READY FOR VERIFICATION" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green

Write-Host @"

Next Steps to Verify Restored Database:
1. Connect directly to the restored test database:
   psql -h $dbHost -p $dbPort -U $dbAdmin -d $testDb

2. Run the automated schema and data verification query suite:
   psql -h $dbHost -p $dbPort -U $dbAdmin -d $testDb -f 05-verify-restoration.sql

3. Run the Activity 4 Role-Based Access Control verification suite:
   psql -h $dbHost -p $dbPort -U $dbAdmin -d $testDb -f 06-verify-access-control.sql
"@ -ForegroundColor Magenta

