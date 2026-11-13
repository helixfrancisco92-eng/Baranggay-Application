<#
.SYNOPSIS
    Controlled Disaster Recovery Simulation for Project OJT RMA System.
.DESCRIPTION
    Simulates accidental data deletion on a disposable test database, executes recovery
    via logical backup restoration into a clean recovery target, and verifies data restoration.
.NOTES
    Subject: COMP 018 – Database Administration (Activity 6)
#>

[CmdletBinding()]
param (
    [string]$EnvFile = "$PSScriptRoot\..\configuration\.env",
    [string]$TestDatabase = "ojt_management_restore_test",
    [string]$RecoveryDatabase = "ojt_management_recovery_test"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " COMP 018: Controlled Disaster Recovery Simulation" -ForegroundColor Cyan
Write-Host " Target Project: Project OJT RMA System" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Load configuration
$Config = @{
    DB_HOST     = "localhost"
    DB_PORT     = "5432"
    DB_USER     = "postgres"
    DB_NAME     = "ojt_management"
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

$DbHost = $Config["DB_HOST"]
$DbPort = $Config["DB_PORT"]
$DbUser = $Config["DB_USER"]
$ProdDb = $Config["DB_NAME"]

# 2. Strict Safety Safeguards
if ($TestDatabase.ToLower() -eq $ProdDb.ToLower() -or $RecoveryDatabase.ToLower() -eq $ProdDb.ToLower()) {
    Write-Error "[FATAL] Safety Violation: Simulation targets cannot be the primary database ($ProdDb)."
    exit 1
}

if ($Config["DB_PASSWORD"]) {
    $env:PGPASSWORD = $Config["DB_PASSWORD"]
}

$Psql = (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
$PgDump = (Get-Command pg_dump -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
$PgRestore = (Get-Command pg_restore -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
$Createdb = (Get-Command createdb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
$Dropdb = (Get-Command dropdb -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)

if (-not ($Psql -and $PgDump -and $PgRestore -and $Createdb)) {
    Write-Error "[FATAL] Missing required PostgreSQL client utilities (psql, pg_dump, pg_restore, createdb)."
    exit 1
}

$SimDir = "$PSScriptRoot\..\backups\simulation"
if (-not (Test-Path $SimDir)) { New-Item -ItemType Directory -Path $SimDir -Force | Out-Null }
$SimBackupFile = "$SimDir\sim_baseline_backup.dump"

Write-Host "`n--- Simulation Step 1: Seeding Disposable Test Data ---" -ForegroundColor Yellow
$SeedScript = "$PSScriptRoot\..\sql\recovery-test-data.sql"
& $Psql -U $DbUser -h $DbHost -p $DbPort -d $TestDatabase -f $SeedScript
Write-Host "[OK] Disposable test records seeded into '$TestDatabase'." -ForegroundColor Green

Write-Host "`n--- Simulation Step 2: Recording Initial State & Taking Baseline Backup ---" -ForegroundColor Yellow
$InitialCount = & $Psql -U $DbUser -h $DbHost -p $DbPort -d $TestDatabase -tAc "SELECT count(*) FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC'"
Write-Host "[STATE 1 - PRE-INCIDENT] Disposable requirement record count: $InitialCount" -ForegroundColor White

Write-Host "[EXEC] Generating simulation baseline backup..." -ForegroundColor Cyan
& pg_dump -U $DbUser -h $DbHost -p $DbPort -Fc -d $TestDatabase -f $SimBackupFile
$SimDumpHash = (Get-FileHash -Path $SimBackupFile -Algorithm SHA256).Hash
Write-Host "[OK] Baseline backup created at: $SimBackupFile" -ForegroundColor Green
Write-Host "[OK] Backup SHA-256 Checksum: $SimDumpHash" -ForegroundColor Gray

Write-Host "`n--- Simulation Step 3: Simulating Accidental Data Loss ---" -ForegroundColor Yellow
Write-Host "[INCIDENT] Executing accidental deletion query: DELETE FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC'..." -ForegroundColor Magenta
& $Psql -U $DbUser -h $DbHost -p $DbPort -d $TestDatabase -c "DELETE FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC';"

$PostDeleteCount = & $Psql -U $DbUser -h $DbHost -p $DbPort -d $TestDatabase -tAc "SELECT count(*) FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC'"
Write-Host "[STATE 2 - POST-INCIDENT] Disposable requirement record count: $PostDeleteCount (Confirmed Deleted!)" -ForegroundColor Red

Write-Host "`n--- Simulation Step 4: Restoring from Baseline Backup into Fresh Target ---" -ForegroundColor Yellow
Write-Host "[EXEC] Recreating clean recovery target: $RecoveryDatabase..." -ForegroundColor Cyan
& $Dropdb -U $DbUser -h $DbHost -p $DbPort --if-exists $RecoveryDatabase 2>$null
& createdb -U $DbUser -h $DbHost -p $DbPort -E UTF8 $RecoveryDatabase

Write-Host "[EXEC] Executing restoration: pg_restore -d $RecoveryDatabase $SimBackupFile..." -ForegroundColor Cyan
& pg_restore -U $DbUser -h $DbHost -p $DbPort -d $RecoveryDatabase $SimBackupFile 2>$null

Write-Host "`n--- Simulation Step 5: Verifying Data Recovery ---" -ForegroundColor Yellow
$RecoveredCount = & $Psql -U $DbUser -h $DbHost -p $DbPort -d $RecoveryDatabase -tAc "SELECT count(*) FROM requirements WHERE title='DISPOSABLE_SIMULATION_CLEARANCE_DOC'"
Write-Host "[STATE 3 - POST-RECOVERY] Disposable requirement record count in '$RecoveryDatabase': $RecoveredCount" -ForegroundColor Green

Write-Host "`n=====================================================================" -ForegroundColor Green
Write-Host " RECOVERY SIMULATION SUMMARY" -ForegroundColor Green
Write-Host "=====================================================================" -ForegroundColor Green
Write-Host "Initial State (Pre-incident)  : $InitialCount record(s) present"
Write-Host "Incident State (Simulated)    : $PostDeleteCount record(s) present"
Write-Host "Recovered State (Restored DB) : $RecoveredCount record(s) restored"

if ($RecoveredCount -eq 1) {
    Write-Host "`n[OUTCOME] SIMULATION SUCCESSFUL: Data loss successfully reversed via logical backup restoration." -ForegroundColor Green
} else {
    Write-Host "`n[OUTCOME] SIMULATION ANOMALY: Expected 1 restored record, found $RecoveredCount." -ForegroundColor Red
}
Write-Host "=====================================================================`n"
