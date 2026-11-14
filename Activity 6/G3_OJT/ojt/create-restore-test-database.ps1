<#
.SYNOPSIS
    Creates an isolated restoration test database for Project OJT RMA System.
.DESCRIPTION
    Safely creates a disposable database (e.g. ojt_management_restore_test) using createdb.
    Strictly prevents destructive overwrites against the original database.
.NOTES
    Subject: COMP 018 – Database Administration (Activity 6)
#>

[CmdletBinding()]
param (
    [string]$EnvFile = "$PSScriptRoot\..\configuration\.env",
    [string]$TestDatabaseName
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " COMP 018: Create Isolated Restore Test Database" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Load configuration
$Config = @{
    DB_HOST          = "localhost"
    DB_PORT          = "5432"
    DB_NAME          = "ojt_management"
    DB_USER          = "postgres"
    RESTORE_TEST_DB  = "ojt_management_restore_test"
}

if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $key = $parts[0].Trim()
            $val = $parts[1].Trim()
            if ($val -ne "" -and -not $val.StartsWith("<")) {
                $Config[$key] = $val
            }
        }
    }
}

if ($TestDatabaseName) { $Config["RESTORE_TEST_DB"] = $TestDatabaseName }

$DbHost = $Config["DB_HOST"]
$DbPort = $Config["DB_PORT"]
$DbUser = $Config["DB_USER"]
$ProdDb = $Config["DB_NAME"]
$TestDb = $Config["RESTORE_TEST_DB"]

# 2. Strict Safety Guard: Never allow target to match primary database
if ($TestDb.ToLower() -eq $ProdDb.ToLower() -or $TestDb.ToLower() -eq "ojt_management" -or $TestDb.ToLower() -eq "ojt_mangementdb") {
    Write-Error "[FATAL] Safety Violation: Test database name ($TestDb) matches primary database ($ProdDb). Refusing to proceed to prevent data loss."
    exit 1
}

Write-Host "[OK] Safety Check Passed: Test target '$TestDb' is distinct from primary '$ProdDb'." -ForegroundColor Green

if ($Config["DB_PASSWORD"]) {
    $env:PGPASSWORD = $Config["DB_PASSWORD"]
}

# 3. Check for createdb utility
$Createdb = (Get-Command createdb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if (-not $Createdb) {
    Write-Error "[FATAL] 'createdb' utility not found on PATH."
    exit 1
}

# 4. Check if test database already exists and recreate if needed
$Dropdb = (Get-Command dropdb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
$Psql = (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)

if ($Psql) {
    $DbExists = & $Psql -U $DbUser -h $DbHost -p $DbPort -tAc "SELECT 1 FROM pg_database WHERE datname='$TestDb'" 2>$null
    if ($DbExists -eq "1") {
        Write-Host "[WARN] Existing test database '$TestDb' detected. Dropping to ensure fresh test state..." -ForegroundColor Yellow
        if ($Dropdb) {
            & $Dropdb -U $DbUser -h $DbHost -p $DbPort $TestDb
        } else {
            & $Psql -U $DbUser -h $DbHost -p $DbPort -c "DROP DATABASE IF EXISTS `"$TestDb`";"
        }
    }
}

# 5. Create fresh disposable test database
Write-Host "[EXEC] Creating empty test database '$TestDb'..." -ForegroundColor Cyan
& createdb -U $DbUser -h $DbHost -p $DbPort -E UTF8 $TestDb
$ExitCode = $LASTEXITCODE

if ($ExitCode -eq 0) {
    Write-Host "`n=====================================================================" -ForegroundColor Green
    Write-Host " TEST DATABASE CREATED SUCCESSFULLY: $TestDb" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
} else {
    Write-Error "[FAIL] Failed to create test database '$TestDb' (Exit code: $ExitCode)."
    exit 1
}
