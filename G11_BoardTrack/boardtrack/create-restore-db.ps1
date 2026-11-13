# ==============================================================================
# Script: create-restore-db.ps1
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Provision Isolated Empty PostgreSQL Restoration Test Database
# OS / Environment: Windows PowerShell
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$RestoreDb = "boardtrack_db_activity6_restore_test",

    [Parameter(Mandatory=$false)]
    [string]$OriginalDb = "boardtrack_db",

    [Parameter(Mandatory=$false)]
    [string]$AdminUser = "postgres",

    [Parameter(Mandatory=$false)]
    [string]$HostName = "localhost",

    [Parameter(Mandatory=$false)]
    [int]$Port = 5432,

    [Parameter(Mandatory=$false)]
    [switch]$ForceDropExisting = $false
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  BoardTrack Provision Isolated Restoration Database — COMP 018" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Target Host     : ${HostName}:${Port}"
Write-Host "Admin User      : $AdminUser"
Write-Host "Restoration DB  : $RestoreDb"
Write-Host "Live DB Guard   : $OriginalDb"
Write-Host "===================================================================="

# CRITICAL SAFETY CHECK: NEVER TARGET LIVE DATABASE
if ($RestoreDb.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    Write-Host "[FATAL ERROR] Restoration database name matches the live database name ($OriginalDb)!" -ForegroundColor Red
    Write-Host "[FATAL ERROR] Operation aborted to prevent overwriting production data." -ForegroundColor Red
    exit 1
}

$createdbCmd = "createdb"
$dropdbCmd = "dropdb"
$psqlCmd = "psql"

if (-not (Get-Command createdb -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\Program Files\PostgreSQL\18\bin\createdb.exe") {
        $createdbCmd = "C:\Program Files\PostgreSQL\18\bin\createdb.exe"
        $dropdbCmd = "C:\Program Files\PostgreSQL\18\bin\dropdb.exe"
        $psqlCmd = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
    }
}

# Check if database already exists
Write-Host "[INFO] Checking if '$RestoreDb' already exists..." -ForegroundColor Yellow
$checkSql = "SELECT 1 FROM pg_database WHERE datname = '$RestoreDb';"
$dbExists = & $psqlCmd -h $HostName -p $Port -U $AdminUser -tAc $checkSql 2>&1

if ($dbExists -match "1") {
    Write-Host "[WARNING] Database '$RestoreDb' already exists." -ForegroundColor Yellow
    if ($ForceDropExisting) {
        Write-Host "[INFO] -ForceDropExisting supplied: Dropping existing isolated test database '$RestoreDb'..." -ForegroundColor Yellow
        & $dropdbCmd -h $HostName -p $Port -U $AdminUser $RestoreDb 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Host "[ERROR] Failed to drop existing test database '$RestoreDb'." -ForegroundColor Red
            exit $LASTEXITCODE
        }
        Write-Host "[OK] Cleaned previous test database." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Database already exists. Run with -ForceDropExisting to recreate from scratch, or proceed to restore." -ForegroundColor Cyan
        exit 0
    }
}

# Provision new database
Write-Host "[INFO] Creating clean restoration database: '$RestoreDb'..." -ForegroundColor Yellow
& $createdbCmd -h $HostName -p $Port -U $AdminUser $RestoreDb 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "  ISOLATED TEST DATABASE PROVISIONED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "Database Name   : $RestoreDb"
    Write-Host "Status          : NEW AND EMPTY"
    Write-Host "Live Isolation  : VERIFIED SEPARATE FROM $OriginalDb"
    Write-Host "Next Step       : Execute restore.ps1 -RestoreDb '$RestoreDb'"
    Write-Host "===================================================================="
} else {
    Write-Host "[ERROR] createdb failed with exit code $LASTEXITCODE." -ForegroundColor Red
    exit $LASTEXITCODE
}

