<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: create-restore-db.ps1
Purpose: Provision Isolated Empty Test Database for Restoration Validation
==============================================================================
#>
[CmdletBinding()]
param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 5432,
    [string]$AdminUser = "postgres",
    [string]$RestoreDb = "grp_binarysisters_projectdb_activity6_restore_test",
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin",
    [switch]$ForceRecreate
)

$ErrorActionPreference = "Stop"
$originalDb = "grp_binarysisters_projectdb"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - Provision Isolated Restoration Database (PowerShell)" -ForegroundColor Cyan
Write-Host " Target Test Database : $RestoreDb" -ForegroundColor Cyan
Write-Host " Host / Port          : ${HostName}:${Port} | Admin: $AdminUser" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# CRITICAL SAFETY CHECK: NEVER RESTORE OVER ORIGINAL DATABASE
if ($RestoreDb.Trim().ToLower() -eq $originalDb.ToLower()) {
    Write-Host "FATAL SECURITY ERROR: Target restoration database cannot equal the live database '$originalDb'!" -ForegroundColor Red
    throw "Safety boundary triggered: restore target equals production database name."
}

# Resolve binaries
$psqlCmd = Get-Command "psql" -ErrorAction SilentlyContinue
$createdbCmd = Get-Command "createdb" -ErrorAction SilentlyContinue
$dropdbCmd = Get-Command "dropdb" -ErrorAction SilentlyContinue

$psqlPath = if ($psqlCmd) { $psqlCmd.Source } else { Join-Path $PsqlPath "psql.exe" }
$createdbPath = if ($createdbCmd) { $createdbCmd.Source } else { Join-Path $PsqlPath "createdb.exe" }
$dropdbPath = if ($dropdbCmd) { $dropdbCmd.Source } else { Join-Path $PsqlPath "dropdb.exe" }

if (-not (Test-Path $psqlPath) -or -not (Test-Path $createdbPath)) {
    throw "PostgreSQL administrative utilities (psql / createdb) not found at '$PsqlPath'."
}

# Secure password acquisition
if (-not $env:PGPASSWORD) {
    $securePw = Read-Host "Enter password for administrative user '$AdminUser'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# Check if target database already exists
$checkSql = "SELECT 1 FROM pg_database WHERE datname='$RestoreDb';"
$dbExists = & $psqlPath -h $HostName -p $Port -U $AdminUser -d postgres -tAc $checkSql 2>$null

if ($dbExists.Trim() -eq "1") {
    Write-Host "Notice: Test database '$RestoreDb' already exists." -ForegroundColor Yellow
    if ($ForceRecreate -or ($Host.UI.PromptForChoice("Database Exists", "Recreate empty database '$RestoreDb'?", @('&Yes', '&No'), 1) -eq 0)) {
        Write-Host "Terminating active connections to '$RestoreDb'..."
        $termSql = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname='$RestoreDb' AND pid <> pg_backend_pid();"
        & $psqlPath -h $HostName -p $Port -U $AdminUser -d postgres -c $termSql | Out-Null
        
        Write-Host "Dropping '$RestoreDb'..."
        & $dropdbPath -h $HostName -p $Port -U $AdminUser $RestoreDb
    } else {
        Write-Host "Preserving existing test database. Exiting."
        exit 0
    }
}

Write-Host "Creating empty test database '$RestoreDb'..." -ForegroundColor Yellow
& $createdbPath -h $HostName -p $Port -U $AdminUser -O $AdminUser $RestoreDb

Write-Host "Enabling required extensions in '$RestoreDb'..." -ForegroundColor Yellow
$extSql = "CREATE EXTENSION IF NOT EXISTS btree_gist; CREATE EXTENSION IF NOT EXISTS pgcrypto;"
& $psqlPath -h $HostName -p $Port -U $AdminUser -d $RestoreDb -c $extSql

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host " PROVISIONING SUCCESSFUL: Test database '$RestoreDb' is ready." -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green

