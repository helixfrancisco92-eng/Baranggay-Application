# ==============================================================================
# BrewPOS — Controlled Disaster Recovery Simulation Runner (PowerShell)
# Course: COMP 018 — Database Administration (Activity 6)
# Target Database: grp_brewposdb_recovery_test (DISPOSABLE DATABASE ONLY)
# Safety Rule: NEVER operates on or deletes records from production 'grp_brewposdb'!
# ==============================================================================

[CmdletBinding()]
param (
    [string]$EnvFile = "../configuration/.env",
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$OriginalDb = "grp_brewposdb",
    [string]$RecoveryDb = "grp_brewposdb_recovery_test",
    [string]$Username = "postgres",
    [string]$BackupDir = "../backups"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS: Controlled Disaster Recovery Simulation Runner        " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Load configuration
if (Test-Path $EnvFile) {
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $varName = $parts[0].Trim()
            $varVal = $parts[1].Trim()
            switch ($varName) {
                "DB_HOST"          { $HostName = $varVal }
                "DB_PORT"          { $Port = $varVal }
                "DB_NAME"          { $OriginalDb = $varVal }
                "RECOVERY_TEST_DB" { $RecoveryDb = $varVal }
                "DB_SUPERUSER"     { $Username = $varVal }
                "DB_PASSWORD"      { $env:PGPASSWORD = $varVal }
            }
        }
    }
}

# 2. Strict Safety Assertion
if ($RecoveryDb.Trim().ToLower() -eq $OriginalDb.Trim().ToLower()) {
    Write-Error "[CRITICAL SAFETY VIOLATION] Target recovery database cannot match production database '$OriginalDb'. Aborted."
    exit 1
}

Write-Host "[SAFETY VALIDATED] Recovery Target: '$RecoveryDb'" -ForegroundColor Green
Write-Host "                   Production DB:   '$OriginalDb' (PROTECTED)" -ForegroundColor Gray

# 3. Locate PostgreSQL binaries
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

if (-not $env:PGPASSWORD) {
    $securePass = Read-Host "Enter password for PostgreSQL user '$Username'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# 4. Provision fresh recovery sandbox database
Write-Host "`n[STEP 1/6] Provisioning clean disposable recovery database '$RecoveryDb'..." -ForegroundColor Yellow
$terminateCmd = "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '$RecoveryDb' AND pid <> pg_backend_pid();"
& psql -U $Username -h $HostName -p $Port -d postgres -c $terminateCmd 2>$null

& dropdb --if-exists -U $Username -h $HostName -p $Port $RecoveryDb 2>$null
& createdb -U $Username -h $HostName -p $Port -E UTF8 $RecoveryDb
if ($LASTEXITCODE -ne 0) {
    Write-Error "[ERROR] Failed to provision recovery sandbox database '$RecoveryDb'."
    exit 1
}

# 5. Populate initial schema from base backup or schema script
Write-Host "`n[STEP 2/6] Restoring baseline schema into '$RecoveryDb'..." -ForegroundColor Yellow
$baseDump = Get-ChildItem -Path $BackupDir -Filter "*.dump" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1

if ($baseDump) {
    Write-Host "      Restoring base dump: $($baseDump.FullName)" -ForegroundColor Gray
    & pg_restore -U $Username -h $HostName -p $Port -d $RecoveryDb --no-owner $baseDump.FullName 2>$null
} else {
    Write-Host "      No base dump found. Restoring baseline from ../../brewpos/database/schema.sql and seed.sql..." -ForegroundColor Gray
    & psql -U $Username -h $HostName -p $Port -d $RecoveryDb -f "../../brewpos/database/schema.sql"
    & psql -U $Username -h $HostName -p $Port -d $RecoveryDb -f "../../brewpos/database/seed.sql"
}

# 6. Insert clearly tagged disposable test record
Write-Host "`n[STEP 3/6] Inserting disposable simulation record..." -ForegroundColor Yellow
$insertSql = @"
INSERT INTO public.menu_category (category_name) VALUES ('__RECOVERY_TEST_CATEGORY__') ON CONFLICT (category_name) DO NOTHING;
INSERT INTO public.menu_item (category_id, item_name, price, is_active)
SELECT c.category_id, '__DISPOSABLE_TEST_ITEM_TO_BE_LOST__', 199.95, TRUE
FROM public.menu_category c WHERE c.category_name = '__RECOVERY_TEST_CATEGORY__'
ON CONFLICT (category_id, item_name) DO UPDATE SET price = 199.95;
"@
& psql -U $Username -h $HostName -p $Port -d $RecoveryDb -c $insertSql

# Verify initial presence
$initialQuery = "SELECT item_id, item_name, price FROM public.menu_item WHERE item_name = '__DISPOSABLE_TEST_ITEM_TO_BE_LOST__';"
$initialRecord = (& psql -U $Username -h $HostName -p $Port -d $RecoveryDb -c $initialQuery)
Write-Host "--- INITIAL RECORD STATE (BEFORE INCIDENT) ---" -ForegroundColor Cyan
Write-Host $initialRecord

# 7. Create Point-In-Time Backup capturing the pre-incident state
Write-Host "`n[STEP 4/6] Taking pre-incident snapshot backup of recovery sandbox..." -ForegroundColor Yellow
$simBackupFile = Join-Path $BackupDir "brewpos_sim_pre_incident.dump"
& pg_dump -U $Username -h $HostName -p $Port -Fc -d $RecoveryDb -f $simBackupFile
Write-Host "      Snapshot saved to: $simBackupFile" -ForegroundColor Green

# 8. Simulate Data Loss Incident (Accidental / Malicious deletion)
Write-Host "`n[STEP 5/6] Simulating data loss: DELETING disposable record..." -ForegroundColor Red
$deleteSql = "DELETE FROM public.menu_item WHERE item_name = '__DISPOSABLE_TEST_ITEM_TO_BE_LOST__';"
& psql -U $Username -h $HostName -p $Port -d $RecoveryDb -c $deleteSql

$lossQuery = "SELECT COUNT(*) AS matching_rows FROM public.menu_item WHERE item_name = '__DISPOSABLE_TEST_ITEM_TO_BE_LOST__';"
$lossResult = (& psql -U $Username -h $HostName -p $Port -d $RecoveryDb -t -A -c $lossQuery).Trim()

Write-Host "--- POST-INCIDENT STATE ---" -ForegroundColor Magenta
Write-Host "Matching test rows remaining in database: $lossResult (Expected: 0 - DATA LOSS CONFIRMED)" -ForegroundColor Yellow

# 9. Execute Recovery: Restore pre-incident backup into clean sandbox
Write-Host "`n[STEP 6/6] Executing database recovery from pre-incident backup..." -ForegroundColor Yellow
& dropdb -U $Username -h $HostName -p $Port $RecoveryDb
& createdb -U $Username -h $HostName -p $Port -E UTF8 $RecoveryDb
& pg_restore -U $Username -h $HostName -p $Port -d $RecoveryDb --no-owner $simBackupFile 2>$null

# 10. Post-Recovery Validation
$recoveryQuery = "SELECT item_id, item_name, price, is_active FROM public.menu_item WHERE item_name = '__DISPOSABLE_TEST_ITEM_TO_BE_LOST__';"
$recoveredRecord = (& psql -U $Username -h $HostName -p $Port -d $RecoveryDb -c $recoveryQuery)

Write-Host "--- POST-RECOVERY RECORD STATE ---" -ForegroundColor Green
Write-Host $recoveredRecord

$recoveredCount = (& psql -U $Username -h $HostName -p $Port -d $RecoveryDb -t -A -c "SELECT COUNT(*) FROM public.menu_item WHERE item_name = '__DISPOSABLE_TEST_ITEM_TO_BE_LOST__';").Trim()

Write-Host "=================================================================" -ForegroundColor Cyan
if ([int]$recoveredCount -ge 1) {
    Write-Host " [RECOVERY SIMULATION SUCCESSFUL] The lost disposable test record was successfully restored!" -ForegroundColor Green
} else {
    Write-Host " [RECOVERY SIMULATION FAILED] Record could not be found in recovered database." -ForegroundColor Red
}
Write-Host " Production Database: Remained 100% UNTOUCHED and PROTECTED." -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

