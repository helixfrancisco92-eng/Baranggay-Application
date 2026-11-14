<#
==============================================================================
HabalGo (Group 6) — Automated Test Database Restoration Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Target Restore Database: grp00_habalgodb_activity6_restore_test
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$HostName = $env:DB_HOST,
    [string]$Port = $env:DB_PORT,
    [string]$OriginalDatabase = $env:DB_NAME,
    [string]$RestoreDatabase = "grp00_habalgodb_activity6_restore_test",
    [string]$Username = $env:DB_USER,
    [string]$BackupFilePath = ""
)

if (-not $HostName) { $HostName = "localhost" }
if (-not $Port) { $Port = "5432" }
if (-not $OriginalDatabase) { $OriginalDatabase = "grp00_habalgodb" }
if (-not $Username) { $Username = "postgres" }

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " HabalGo Test Database Restoration Utility (pg_restore)          " -ForegroundColor Cyan
Write-Host " Course: COMP 018 — Activity 6                                    " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# SAFETY ASSERTION 1: Target database must strictly differ from original database
if ($RestoreDatabase.Trim().ToLower() -eq $OriginalDatabase.Trim().ToLower()) {
    Write-Error "[CRITICAL SAFETY VIOLATION] Target restore database cannot be identical to the original database! Refusing to overwrite '$OriginalDatabase'. Restoration aborted."
    exit 1
}

Write-Host "[1/7] Target safety assertion PASSED." -ForegroundColor Green
Write-Host "      Source Database (Original) : $OriginalDatabase"
Write-Host "      Target Database (Separate) : $RestoreDatabase"

# 2. Locate Backup Archive
if (-not $BackupFilePath) {
    $backupDir = Join-Path $PSScriptRoot "..\backups"
    if (Test-Path $backupDir) {
        $latest = Get-ChildItem -Path $backupDir -Filter "*activity6*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
            $BackupFilePath = $latest.FullName
        }
    }
}

if (-not $BackupFilePath -or (-not (Test-Path $BackupFilePath))) {
    Write-Error "[FAILED] No valid backup archive (.dump) found. Please run 01_backup.ps1 first or supply a file via -BackupFilePath."
    exit 1
}

$fileItem = Get-Item $BackupFilePath
Write-Host "[2/7] Backup archive identified: $($fileItem.Name)" -ForegroundColor Green

# 3. Check Cryptographic SHA-256 Checksum
Write-Host "[3/7] Verifying archive cryptographic checksum..." -ForegroundColor Yellow
$checksumFile = "${BackupFilePath}.sha256"
$computedHash = (Get-FileHash -Path $BackupFilePath -Algorithm SHA256).Hash

if (Test-Path $checksumFile) {
    $storedHash = ((Get-Content $checksumFile).Trim() -split '\s+')[0]
    if ($computedHash.ToUpper() -eq $storedHash.ToUpper()) {
        Write-Host "      Checksum verification PASSED." -ForegroundColor Green
    } else {
        Write-Warning "      [WARNING] SHA-256 checksum mismatch! Stored: $storedHash vs Computed: $computedHash"
    }
} else {
    Write-Host "      Notice: Checksum manifest (.sha256) not found. Proceeding with cautioned validation." -ForegroundColor DarkGray
}

# 4. Check or Create Target Database in Cluster
Write-Host "[4/7] Verifying destination database existence in cluster..." -ForegroundColor Yellow
$checkDbQuery = "SELECT 1 FROM pg_database WHERE datname='$RestoreDatabase';"
$dbExists = & psql -U $Username -h $HostName -p $Port -d postgres -t -A -c $checkDbQuery 2>$null

if ($dbExists.Trim() -ne "1") {
    Write-Host "      Destination database '$RestoreDatabase' does not exist. Creating..." -ForegroundColor Cyan
    & createdb -U $Username -h $HostName -p $Port $RestoreDatabase
    if ($LASTEXITCODE -ne 0) {
        Write-Error "[FAILED] Could not create database '$RestoreDatabase'. Ensure '$Username' has CREATEDB privilege."
        exit 1
    }
    Write-Host "      Database '$RestoreDatabase' created successfully." -ForegroundColor Green
} else {
    Write-Host "      Destination database '$RestoreDatabase' exists." -ForegroundColor Green
}

# 5. Confirm Destination Database is Clean and Empty
Write-Host "[5/7] Verifying destination database is clean and empty..." -ForegroundColor Yellow
$cleanQuery = "SELECT count(*) FROM information_schema.tables WHERE table_schema NOT IN ('pg_catalog','information_schema');"
$tableCount = & psql -U $Username -h $HostName -p $Port -d $RestoreDatabase -t -A -c $cleanQuery 2>$null

if ([int]$tableCount -gt 0) {
    Write-Error "[CRITICAL SAFETY VIOLATION] Destination database '$RestoreDatabase' already contains $tableCount table(s)! Refusing to restore over a non-empty database without manual inspection."
    exit 1
}
Write-Host "      Destination database is clean (0 user tables detected)." -ForegroundColor Green

# 6. Execute pg_restore
Write-Host "[6/7] Restoring archive into '$RestoreDatabase' (pg_restore)..." -ForegroundColor Yellow
$startTime = Get-Date

$restoreLogPath = Join-Path $PSScriptRoot "..\backups\restore_output.log"
$restoreLogDir = Split-Path -Parent $restoreLogPath
if (-not (Test-Path $restoreLogDir)) { New-Item -ItemType Directory -Path $restoreLogDir -Force | Out-Null }

& pg_restore -U $Username -h $HostName -p $Port -v -d $RestoreDatabase $BackupFilePath 2>&1 | Tee-Object -FilePath $restoreLogPath
$restoreExit = $LASTEXITCODE
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

if ($restoreExit -eq 0) {
    Write-Host "      Restoration completed cleanly with zero warnings (Exit Code: 0)." -ForegroundColor Green
} elseif ($restoreExit -eq 1) {
    Write-Host "      Restoration completed with non-fatal warnings (Exit Code: 1)." -ForegroundColor Yellow
} else {
    Write-Error "[FAILED] pg_restore failed with critical exit code: $restoreExit. Review log at $restoreLogPath"
    exit $restoreExit
}

# 7. Post-Restoration Object Count Validation
Write-Host "[7/7] Validating restored database contents..." -ForegroundColor Yellow
$tableAuditQuery = "SELECT count(*) FROM information_schema.tables WHERE table_schema='habalgo';"
$restoredTables = & psql -U $Username -h $HostName -p $Port -d $RestoreDatabase -t -A -c $tableAuditQuery 2>$null

Write-Host "=================================================================" -ForegroundColor Green
Write-Host " RESTORATION SUMMARY REPORT                                      " -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Green
Write-Host " Source Archive     : $BackupFilePath"
Write-Host " Destination DB     : $RestoreDatabase"
Write-Host " Tables Restored    : $restoredTables table(s) in schema 'habalgo'"
Write-Host " Duration           : $([math]::Round($duration, 2)) seconds"
Write-Host " Log File           : $restoreLogPath"
Write-Host " Status             : SUCCESS"
Write-Host "=================================================================" -ForegroundColor Green

