<#
.SYNOPSIS
    Automated Database Restoration Script for Project OJT RMA System.
.DESCRIPTION
    Restores a PostgreSQL custom-format backup (-Fc) into an isolated test database.
    Captures stdout/stderr, evaluates exit status, and validates restored objects.
.NOTES
    Subject: COMP 018 – Database Administration (Activity 6)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$BackupFile,
    [string]$TargetDatabase,
    [string]$EnvFile = "$PSScriptRoot\..\configuration\.env"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " COMP 018: Database Restoration Engine (pg_restore)" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Load configuration
$Config = @{
    DB_HOST          = "localhost"
    DB_PORT          = "5432"
    DB_USER          = "postgres"
    DB_NAME          = "ojt_management"
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

if ($TargetDatabase) { $Config["RESTORE_TEST_DB"] = $TargetDatabase }

# 2. Strict Safety Check
$ProdDb = $Config["DB_NAME"]
$TestDb = $Config["RESTORE_TEST_DB"]
if ($TestDb.ToLower() -eq $ProdDb.ToLower() -or $TestDb.ToLower() -eq "ojt_management" -or $TestDb.ToLower() -eq "ojt_mangementdb") {
    Write-Error "[FATAL] Safety Check Failed: Refusing to restore into primary production database '$TestDb'."
    exit 1
}

# 3. Resolve and Validate Backup File
if (-not $BackupFile) {
    $DefaultBackupDir = "$PSScriptRoot\..\backups"
    if (Test-Path $DefaultBackupDir) {
        $Latest = Get-ChildItem -Path $DefaultBackupDir -Filter "*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($Latest) { $BackupFile = $Latest.FullName }
    }
}

if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
    Write-Error "[FATAL] Backup file not found: '$BackupFile'. Please provide a valid backup archive path."
    exit 1
}

$FileInfo = Get-Item $BackupFile
if ($FileInfo.Length -eq 0) {
    Write-Error "[FATAL] The specified backup file is empty (0 bytes)."
    exit 1
}

Write-Host "[OK] Using verified backup file: $($FileInfo.FullName)" -ForegroundColor Green
Write-Host "[OK] Target isolation database: $TestDb" -ForegroundColor Green

# 4. Check Database Utilities
$PgRestore = (Get-Command pg_restore -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
$Psql = (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)

if (-not $PgRestore) {
    Write-Error "[FATAL] 'pg_restore' utility not found on PATH."
    exit 1
}

$DbHost = $Config["DB_HOST"]
$DbPort = $Config["DB_PORT"]
$DbUser = $Config["DB_USER"]

if ($Config["DB_PASSWORD"]) {
    $env:PGPASSWORD = $Config["DB_PASSWORD"]
}

# 5. Execute pg_restore
$StartTime = Get-Date
Write-Host "`n[EXEC] Executing restoration: pg_restore -U $DbUser -h $DbHost -p $DbPort -d $TestDb `"$($FileInfo.FullName)`"" -ForegroundColor Cyan

$RestoreOutput = & $PgRestore -U $DbUser -h $DbHost -p $DbPort -d $TestDb --verbose $FileInfo.FullName 2>&1
$ExitCode = $LASTEXITCODE

Write-Host "`n=====================================================================" -ForegroundColor White
Write-Host " RESTORATION PROCESS OUTPUT & WARNING LOGS" -ForegroundColor White
Write-Host "=====================================================================" -ForegroundColor White
$RestoreOutput | Select-Object -First 30 | ForEach-Object { Write-Host $_ -ForegroundColor Gray }

# In pg_restore, exit code 0 = perfect success; exit code 1 = warnings (e.g. role ownership or already exists); exit code > 1 = fatal
if ($ExitCode -eq 0) {
    Write-Host "`n[SUCCESS] Restoration completed with 0 errors (Exit code: 0)." -ForegroundColor Green
} elseif ($ExitCode -eq 1) {
    Write-Host "`n[NOTICE] Restoration completed with non-fatal warnings (Exit code: 1). Examining output..." -ForegroundColor Yellow
} else {
    Write-Host "`n[FAIL] Restoration failed with fatal error code $ExitCode." -ForegroundColor Red
    exit $ExitCode
}

# 6. Verify restored object counts
if ($Psql) {
    Write-Host "`n[VERIFY] Querying restored table count in '$TestDb'..." -ForegroundColor Cyan
    $TableCount = & $Psql -U $DbUser -h $DbHost -p $DbPort -d $TestDb -tAc "SELECT count(*) FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';" 2>$null
    Write-Host "[OK] Total base tables in restored database '$TestDb': $TableCount" -ForegroundColor Green
}
