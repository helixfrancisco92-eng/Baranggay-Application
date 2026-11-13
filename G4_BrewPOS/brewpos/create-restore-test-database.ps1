# ==============================================================================
# BrewPOS — Create Disposable Restoration Test Database (PowerShell)
# Course: COMP 018 — Database Administration (Activity 6)
# Safety Rule: NEVER restore over or drop the original 'grp_brewposdb' database!
# ==============================================================================

[CmdletBinding()]
param (
    [string]$EnvFile = "../configuration/.env",
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$OriginalDb = "grp_brewposdb",
    [string]$TestDatabase = "grp_brewposdb_restore_test",
    [string]$Username = "postgres",
    [switch]$ForceRecreate = $true
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS: Provision Isolated Restoration Test Database          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Load configuration if available
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $varName = $parts[0].Trim()
            $varVal = $parts[1].Trim()
            switch ($varName) {
                "DB_HOST"         { $HostName = $varVal }
                "DB_PORT"         { $Port = $varVal }
                "DB_NAME"         { $OriginalDb = $varVal }
                "RESTORE_TEST_DB" { $TestDatabase = $varVal }
                "DB_SUPERUSER"    { $Username = $varVal }
                "DB_PASSWORD"     { $env:PGPASSWORD = $varVal }
            }
        }
    }
}

# 2. Strict Safety Check: Target test database MUST NOT match original database
if ($TestDatabase.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    Write-Error "[CRITICAL SAFETY VIOLATION] Target test database '$TestDatabase' matches the original database '$OriginalDb'. Execution aborted to protect application records."
    exit 1
}

Write-Host "[SAFETY CONFIRMED] Target test database: '$TestDatabase'" -ForegroundColor Green
Write-Host "                   Original production:  '$OriginalDb'" -ForegroundColor Gray

# 3. Locate psql / createdb / dropdb
$commonPgPaths = @(
    "C:\Program Files\PostgreSQL\18\bin",
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin"
)
foreach ($p in $commonPgPaths) {
    if (Test-Path "$p\psql.exe") {
        $env:Path += ";$p"
        break
    }
}

# Prompt for password if missing
if (-not $env:PGPASSWORD) {
    $securePass = Read-Host "Enter password for PostgreSQL user '$Username'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# 4. Check if test database already exists; drop if ForceRecreate is specified
$checkDbQuery = "SELECT 1 FROM pg_database WHERE datname = '$TestDatabase';"
$dbExists = & psql -U $Username -h $HostName -p $Port -d postgres -t -A -c $checkDbQuery 2>$null

if ($dbExists -match "1") {
    if ($ForceRecreate) {
        Write-Host "[INFO] Existing test database '$TestDatabase' found. Terminating active connections and dropping..." -ForegroundColor Yellow
        
        $terminateQuery = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$TestDatabase' AND pid <> pg_backend_pid();"
        & psql -U $Username -h $HostName -p $Port -d postgres -c $terminateQuery 2>$null
        
        & dropdb -U $Username -h $HostName -p $Port $TestDatabase
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to drop existing test database '$TestDatabase'."
            exit $LASTEXITCODE
        }
        Write-Host "      Previous test database dropped cleanly." -ForegroundColor Gray
    } else {
        Write-Host "[INFO] Test database '$TestDatabase' already exists." -ForegroundColor Green
        exit 0
    }
}

# 5. Create fresh empty test database
Write-Host "[PROVISIONING] Creating fresh empty database: '$TestDatabase'..." -ForegroundColor Yellow
& createdb -U $Username -h $HostName -p $Port -E UTF8 -O $Username $TestDatabase
$createExitCode = $LASTEXITCODE

if ($createExitCode -ne 0) {
    Write-Error "[ERROR] Failed to create test database '$TestDatabase' (exit code $createExitCode)."
    exit $createExitCode
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] Disposable test database '$TestDatabase' is ready." -ForegroundColor Green
Write-Host " Server: $HostName`:$Port | Owner: $Username | Encoding: UTF8" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

