<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: create-restore-db.ps1
Purpose: Provision an isolated, clean test database for restoration testing
Safety: CRITICAL - Enforces strict boundary checks against the live database
==============================================================================
#>
[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$AdminUser = "postgres",
    [string]$DbOwner = "canteen_admin",
    [string]$OriginalDb = "canteen_db",
    [string]$RestoreDb = "canteen_db_activity6_restore_test",
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$logsDir = Join-Path $workspaceRoot "logs"

if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - Provision Isolated Restoration Test Database" -ForegroundColor Cyan
Write-Host " Target Test Database : $RestoreDb" -ForegroundColor Cyan
Write-Host " Host / Port          : ${HostName}:${Port}" -ForegroundColor Cyan
Write-Host " Admin User           : $AdminUser | Database Owner: $DbOwner" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# STRICT SAFETY CHECK
if ($RestoreDb.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    throw "FATAL SECURITY ERROR: Destination restore database cannot match the original database ('$OriginalDb')! Aborting to protect primary data."
}

# Locate psql, createdb, dropdb
$createdbCmd = Get-Command "createdb" -ErrorAction SilentlyContinue
$psqlCmd = Get-Command "psql" -ErrorAction SilentlyContinue
$dropdbCmd = Get-Command "dropdb" -ErrorAction SilentlyContinue

$createdbPath = if ($createdbCmd) { $createdbCmd.Source } else { Join-Path $PsqlPath "createdb.exe" }
$psqlPathExe = if ($psqlCmd) { $psqlCmd.Source } else { Join-Path $PsqlPath "psql.exe" }
$dropdbPath = if ($dropdbCmd) { $dropdbCmd.Source } else { Join-Path $PsqlPath "dropdb.exe" }

if (-not (Test-Path $createdbPath)) { throw "createdb.exe not found at '$createdbPath'." }

# Acquire password securely
$securePw = $null
if (-not $env:PGPASSWORD) {
    $securePw = Read-Host "Enter password for administrative user '$AdminUser'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

try {
    # Check if target exists
    $existsQuery = "SELECT 1 FROM pg_database WHERE datname='$RestoreDb';"
    $existsResult = (& $psqlPathExe -h $HostName -p $Port -U $AdminUser -d postgres -tAc $existsQuery).Trim()

    if ($existsResult -eq "1") {
        Write-Warning "Test restoration database '$RestoreDb' already exists from a prior test run."
        $confirm = Read-Host "Do you want to drop and recreate '$RestoreDb'? (y/n)"
        if ($confirm -match '^[Yy]') {
            Write-Host "Dropping existing test database '$RestoreDb'..." -ForegroundColor Yellow
            & $dropdbPath -h $HostName -p $Port -U $AdminUser $RestoreDb
            if ($LASTEXITCODE -ne 0) { throw "Failed to drop existing test database." }
        } else {
            Write-Host "Database creation aborted by user."
            return
        }
    }

    Write-Host "Creating clean test database '$RestoreDb' with owner '$DbOwner'..." -ForegroundColor Yellow
    & $createdbPath -h $HostName -p $Port -U $AdminUser -O $DbOwner $RestoreDb
    if ($LASTEXITCODE -ne 0) {
        throw "createdb failed with exit code $LASTEXITCODE."
    }

    Write-Host "[PASS] Successfully provisioned isolated test database: $RestoreDb" -ForegroundColor Green
    Write-Host "Ready for restoration. Run 'restore.ps1' to proceed." -ForegroundColor Cyan
}
catch {
    Write-Error "Database provisioning failed: $_"
    exit 1
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

