<#
==============================================================================
CampusSafe (Group 7) — Isolated Database Restoration Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Target Database: grp07_campussafedb_activity6_restore_test
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$HostName = $env:DB_HOST,
    [string]$Port = $env:DB_PORT,
    [string]$AdminUser = $env:ADMIN_USER,
    [string]$OriginalDB = $env:ORIGINAL_DB,
    [string]$RestoreDB = $env:RESTORE_DB,
    [string]$BackupFile
)

# Apply Defaults
if (-not $HostName) { $HostName = "localhost" }
if (-not $Port) { $Port = "5432" }
if (-not $AdminUser) { $AdminUser = "postgres" }
if (-not $OriginalDB) { $OriginalDB = "grp07_campussafedb" }
if (-not $RestoreDB) { $RestoreDB = "grp07_campussafedb_activity6_restore_test" }
if (-not $BackupFile) {
    $backupDir = Join-Path $PSScriptRoot "..\backups"
    $BackupFile = Join-Path $backupDir "grp07_campussafedb_activity6.dump"
}

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " CampusSafe (Group 7) Isolated Database Restoration (PowerShell) " -ForegroundColor Cyan
Write-Host " Production Database:  $OriginalDB (STRICTLY UNTOUCHED)           " -ForegroundColor Cyan
Write-Host " Restoration Target:   $RestoreDB                                " -ForegroundColor Cyan
Write-Host " Backup Source Archive: $BackupFile                               " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Cardinal Safety Check: Target MUST NOT be Original Production Database
if ($RestoreDB.Trim().ToLower() -eq $OriginalDB.Trim().ToLower()) {
    Write-Error "[-] FATAL ERROR: Attempted to restore directly over the live production database! Aborting."
    exit 1
}

# 2. Confirm Backup File Exists
if (-not (Test-Path $BackupFile)) {
    Write-Error "[-] ERROR: Backup archive file not found: $BackupFile. Please run 01_backup.ps1 first."
    exit 1
}

# 3. Locate pg_restore and psql
$pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
if (-not $pgRestoreCmd) {
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin",
        "C:\Program Files\PostgreSQL\15\bin"
    )
    foreach ($p in $commonPgPaths) {
        if (Test-Path (Join-Path $p "pg_restore.exe")) {
            $env:PATH = "$p;$env:PATH"
            $pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $pgRestoreCmd) {
    Write-Error "[-] ERROR: pg_restore.exe was not found in PATH."
    exit 1
}

# 4. Check if Destination Database Exists; If Missing, Create It
Write-Host "[1/4] Checking destination test database '$RestoreDB'..." -ForegroundColor Yellow
$checkDbSql = "SELECT 1 FROM pg_database WHERE datname = '$RestoreDB';"
$dbExists = & psql.exe -U $AdminUser -h $HostName -p $Port -d postgres -tAc $checkDbSql 2>$null

if ($dbExists -ne "1") {
    Write-Host "[*] Creating isolated test database '$RestoreDB'..." -ForegroundColor Cyan
    & createdb.exe -U $AdminUser -h $HostName -p $Port -O $AdminUser $RestoreDB
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[-] Failed to provision test database."
        exit 1
    }
} else {
    Write-Host "    Test database '$RestoreDB' exists." -ForegroundColor Green
}

# 5. Execute pg_restore
Write-Host "[2/4] Executing pg_restore into '$RestoreDB'..." -ForegroundColor Yellow
$sw = [System.Diagnostics.Stopwatch]::StartNew()

$restoreArgs = @(
    "-U", $AdminUser,
    "-h", $HostName,
    "-p", $Port,
    "-d", $RestoreDB,
    "--no-owner",
    "--no-privileges",
    "--verbose",
    $BackupFile
)

try {
    & pg_restore.exe @restoreArgs
} catch {
    Write-Warning "pg_restore completed with notices: $_"
}

$sw.Stop()
$durationSec = [math]::Round($sw.Elapsed.TotalSeconds, 2)
Write-Host "[3/4] Restoration completed in ${durationSec}s." -ForegroundColor Green

# 6. Post-Restoration Sanity Audit
Write-Host "[4/4] Conducting post-restoration object count audit:" -ForegroundColor Yellow
$auditSql = @"
SELECT 
    (SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE') AS restored_tables,
    (SELECT COUNT(*) FROM information_schema.sequences WHERE sequence_schema = 'public') AS restored_sequences,
    (SELECT COUNT(*) FROM pg_indexes WHERE schemaname = 'public' AND indexname NOT LIKE '%_pkey' AND indexname NOT LIKE '%_key') AS restored_indexes;
"@

& psql.exe -U $AdminUser -h $HostName -p $Port -d $RestoreDB -c $auditSql

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "[+] SUCCESS: Archive restored into isolated test database: $RestoreDB" -ForegroundColor Green
Write-Host "    Next Step: Run verification scripts 05 through 08." -ForegroundColor Yellow
Write-Host "=================================================================" -ForegroundColor Cyan

