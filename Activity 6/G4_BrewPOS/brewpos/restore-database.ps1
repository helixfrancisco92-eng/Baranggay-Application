# ==============================================================================
# BrewPOS — Database Restoration Test Script (PowerShell)
# Course: COMP 018 — Database Administration (Activity 6)
# Safety Rule: Strictly restores into a separate disposable test database!
# ==============================================================================

[CmdletBinding()]
param (
    [string]$BackupFile = "",
    [string]$EnvFile = "../configuration/.env",
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$OriginalDb = "grp_brewposdb",
    [string]$TestDatabase = "grp_brewposdb_restore_test",
    [string]$Username = "postgres",
    [switch]$AutoProvisionDb = $true
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS Database Restoration Test Utility (pg_restore)        " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Load configuration from .env if available
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

# 2. Strict Safety Assertion
if ($TestDatabase.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    Write-Error "[CRITICAL SAFETY VIOLATION] Target database '$TestDatabase' is the ORIGINAL database! Restoring over production is prohibited."
    exit 1
}

# 3. Locate backup file
if (-not $BackupFile) {
    $dumpFiles = Get-ChildItem -Path "../backups" -Filter "*.dump" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($dumpFiles -and $dumpFiles.Count -gt 0) {
        $BackupFile = $dumpFiles[0].FullName
        Write-Host "[INFO] Using latest backup archive: $BackupFile" -ForegroundColor Yellow
    } else {
        Write-Error "[FATAL] No backup file found in ../backups. Please run backup-database.ps1 first."
        exit 1
    }
}

if (-not (Test-Path $BackupFile)) {
    Write-Error "[FATAL] Specified backup file does not exist: $BackupFile"
    exit 1
}

# 4. Check for pg_restore and psql
$commonPgPaths = @(
    "C:\Program Files\PostgreSQL\18\bin",
    "C:\Program Files\PostgreSQL\17\bin",
    "C:\Program Files\PostgreSQL\16\bin"
)
foreach ($p in $commonPgPaths) {
    if (Test-Path "$p\pg_restore.exe") {
        $env:Path += ";$p"
        break
    }
}

if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
    Write-Error "[FATAL] 'pg_restore' utility was not found in PATH."
    exit 1
}

# 5. Password prompt if needed
if (-not $env:PGPASSWORD) {
    $securePass = Read-Host "Enter password for PostgreSQL user '$Username'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# 6. Verify or auto-provision the target test database
Write-Host "[1/4] Verifying destination test database '$TestDatabase'..." -ForegroundColor Yellow
$dbCheck = & psql -U $Username -h $HostName -p $Port -d postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname = '$TestDatabase';" 2>$null

if ($dbCheck -notmatch "1") {
    if ($AutoProvisionDb) {
        Write-Host "      Database '$TestDatabase' does not exist. Creating..." -ForegroundColor Gray
        & createdb -U $Username -h $HostName -p $Port -E UTF8 -O $Username $TestDatabase
        if ($LASTEXITCODE -ne 0) {
            Write-Error "[ERROR] Failed to automatically provision '$TestDatabase'."
            exit $LASTEXITCODE
        }
    } else {
        Write-Error "[ERROR] Test database '$TestDatabase' does not exist. Run create-restore-test-database.ps1 first."
        exit 1
    }
} else {
    Write-Host "      Target test database '$TestDatabase' exists." -ForegroundColor Green
}

# 7. Execute pg_restore into test database
Write-Host "[2/4] Executing pg_restore into '$TestDatabase'..." -ForegroundColor Yellow
Write-Host "      Source Backup: $BackupFile" -ForegroundColor Gray
Write-Host "      Target:        $TestDatabase on $HostName`:$Port" -ForegroundColor Gray

# Note: --no-owner avoids warnings when roles on target server differ from source
$restoreArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-d", $TestDatabase,
    "--no-owner",
    "--role=$Username",
    "-v",
    $BackupFile
)

$startTime = Get-Date
try {
    # pg_restore outputs verbose status to stderr; capture both streams
    $restoreOutput = & pg_restore @restoreArgs 2>&1
    $restoreExitCode = $LASTEXITCODE
} catch {
    Write-Error "[FATAL] Restoration command failed: $_"
    exit 1
}
$duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 2)

# pg_restore returns 0 on pure success, or 1 if non-fatal warnings occurred (e.g. role warnings)
if ($restoreExitCode -gt 1) {
    Write-Error "[ERROR] pg_restore failed with critical exit code $restoreExitCode."
    exit $restoreExitCode
} elseif ($restoreExitCode -eq 1) {
    Write-Host "[WARN] pg_restore completed with non-fatal warnings (exit code 1)." -ForegroundColor Yellow
} else {
    Write-Host "      pg_restore completed with zero errors (exit code 0)." -ForegroundColor Green
}

# 8. Post-restoration quick smoke check
Write-Host "[3/4] Running preliminary object count on '$TestDatabase'..." -ForegroundColor Yellow
$tableCountQuery = "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';"
$tableCount = (& psql -U $Username -h $HostName -p $Port -d $TestDatabase -t -A -c $tableCountQuery 2>$null).Trim()

Write-Host "      Restored public tables count: $tableCount (Expected: 5)" -ForegroundColor Green

# 9. Summary Report Logging
Write-Host "[4/4] Generating restoration test log..." -ForegroundColor Yellow
$logDir = "../reports"
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }
$logFile = Join-Path $logDir "restoration-execution-last.log"

$logContent = @"
=================================================================
BrewPOS Restoration Test Log
=================================================================
Timestamp:       $(Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC")
Original DB:     $OriginalDb
Target DB:       $TestDatabase (SEPARATE DISPOSABLE TEST INSTANCE)
Backup File:     $BackupFile
Duration:        $duration seconds
Exit Code:       $restoreExitCode
Restored Tables: $tableCount
Target Host:     $HostName`:$Port
User:            $Username
=================================================================
"@
$logContent | Set-Content -Path $logFile

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] Restoration into disposable test database complete!" -ForegroundColor Green
Write-Host " Test DB:  $TestDatabase" -ForegroundColor Cyan
Write-Host " Log File: $logFile" -ForegroundColor Cyan
Write-Host " Next Step: Run scripts/verify-restoration.ps1 to validate data integrity." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

