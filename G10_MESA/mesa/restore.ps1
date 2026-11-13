<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: restore.ps1
Purpose: Execute Full Database Restoration into Isolated Test Database
==============================================================================
#>
[CmdletBinding()]
param(
    [string]$HostName = "127.0.0.1",
    [int]$Port = 5432,
    [string]$AdminUser = "postgres",
    [string]$RestoreDb = "grp_binarysisters_projectdb_activity6_restore_test",
    [string]$BackupFile = "",
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin"
)

$ErrorActionPreference = "Stop"
$originalDb = "grp_binarysisters_projectdb"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$logsDir = Join-Path $workspaceRoot "logs"
$backupDir = Join-Path $workspaceRoot "backups"

if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - PostgreSQL Database Restoration (PowerShell)" -ForegroundColor Cyan
Write-Host " Target Test Database : $RestoreDb" -ForegroundColor Cyan
Write-Host " Host / Port          : ${HostName}:${Port} | Admin: $AdminUser" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# CRITICAL SAFETY CHECK: NEVER RESTORE OVER ORIGINAL DATABASE
if ($RestoreDb.Trim().ToLower() -eq $originalDb.ToLower()) {
    Write-Host "FATAL SECURITY ERROR: Attempted restoration over original database '$originalDb'!" -ForegroundColor Red
    throw "Safety boundary triggered: restore target equals production database name."
}

# Resolve binaries
$pgRestore = Get-Command "pg_restore" -ErrorAction SilentlyContinue
$psql = Get-Command "psql" -ErrorAction SilentlyContinue

$pgRestorePath = if ($pgRestore) { $pgRestore.Source } else { Join-Path $PsqlPath "pg_restore.exe" }
$psqlPath = if ($psql) { $psql.Source } else { Join-Path $PsqlPath "psql.exe" }

if (-not (Test-Path $pgRestorePath) -or -not (Test-Path $psqlPath)) {
    throw "PostgreSQL utilities (pg_restore / psql) not found at '$PsqlPath'."
}

# Resolve backup file
if ([string]::IsNullOrWhiteSpace($BackupFile)) {
    $latest = Get-ChildItem -Path $backupDir -Filter "*.dump" -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        throw "No .dump archive file found in '$backupDir'. Provide explicit -BackupFile."
    }
    $BackupFile = $latest.FullName
}

if (-not (Test-Path $BackupFile)) {
    throw "Target backup file does not exist: $BackupFile"
}

$filename = Split-Path -Leaf $BackupFile
$restoreLog = Join-Path $logsDir "restore-execution.log"

# Password acquisition
if (-not $env:PGPASSWORD) {
    $securePw = Read-Host "Enter password for administrative user '$AdminUser'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# Confirm destination database exists
$checkSql = "SELECT 1 FROM pg_database WHERE datname='$RestoreDb';"
$dbExists = & $psqlPath -h $HostName -p $Port -U $AdminUser -d postgres -tAc $checkSql 2>$null
if ($dbExists.Trim() -ne "1") {
    throw "Destination database '$RestoreDb' does not exist. Run create-restore-db.ps1 first."
}

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Running pg_restore..." -ForegroundColor Yellow
Write-Host "Source Archive : $filename"
Write-Host "Target DB      : $RestoreDb"
Write-Host "Logging To     : $restoreLog"

# Note on Flags: We execute pg_restore without blind suppression flags like --no-owner or --no-acl
# to ensure authentic replication of production permissions and table ownership.
& $pgRestorePath -h $HostName -p $Port -U $AdminUser -v -d $RestoreDb $BackupFile *> $restoreLog
$exitCode = $LASTEXITCODE

Write-Host "pg_restore finished with exit code: $exitCode"

if ($exitCode -eq 0) {
    Write-Host " -> Restoration completed with ZERO errors or warnings." -ForegroundColor Green
} elseif ($exitCode -eq 1) {
    Write-Host " -> Restoration completed with non-fatal informational notices/warnings (Exit Code 1)." -ForegroundColor Yellow
    Write-Host "    (Common when pre-existing extensions or comments are processed)."
} else {
    Write-Host " -> ERROR: Restoration failed with critical errors (Exit Code $exitCode)." -ForegroundColor Red
    Write-Host "    Review details in: $restoreLog"
    exit $exitCode
}

Write-Host "==============================================================================" -ForegroundColor Green
Write-Host " RESTORATION COMPLETE: Proceeding to SQL verification suites." -ForegroundColor Green
Write-Host " Next Steps: Execute scripts\verify-database.sql and verify-access-control.sql" -ForegroundColor Green
Write-Host "==============================================================================" -ForegroundColor Green

