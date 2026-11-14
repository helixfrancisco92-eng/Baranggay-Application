<#
.SYNOPSIS
    Executes automated SQL verification against restored database.
.DESCRIPTION
    Runs sql/verification-queries.sql against the target restoration database,
    checking tables, record counts, primary keys, foreign keys, and constraints.
.NOTES
    Subject: COMP 018 – Database Administration (Activity 6)
#>

[CmdletBinding()]
param (
    [string]$TargetDatabase,
    [string]$EnvFile = "$PSScriptRoot\..\configuration\.env",
    [string]$SqlScript = "$PSScriptRoot\..\sql\verification-queries.sql"
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " COMP 018: Restored Database Verification Suite" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Load configuration
$Config = @{
    DB_HOST          = "localhost"
    DB_PORT          = "5432"
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

if ($TargetDatabase) { $Config["RESTORE_TEST_DB"] = $TargetDatabase }

$DbHost = $Config["DB_HOST"]
$DbPort = $Config["DB_PORT"]
$DbUser = $Config["DB_USER"]
$TestDb = $Config["RESTORE_TEST_DB"]

if ($Config["DB_PASSWORD"]) {
    $env:PGPASSWORD = $Config["DB_PASSWORD"]
}

$Psql = (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if (-not $Psql) {
    Write-Error "[FATAL] 'psql' client utility not found on PATH."
    exit 1
}

if (-not (Test-Path $SqlScript)) {
    Write-Error "[FATAL] SQL script not found at: $SqlScript"
    exit 1
}

Write-Host "[INFO] Connecting to Test Database: $TestDb" -ForegroundColor White
Write-Host "[INFO] Executing Verification Script: $SqlScript" -ForegroundColor Gray

# 2. Execute SQL verification suite
& $Psql -U $DbUser -h $DbHost -p $DbPort -d $TestDb -f $SqlScript
$ExitCode = $LASTEXITCODE

if ($ExitCode -eq 0) {
    Write-Host "`n[SUCCESS] Verification queries executed successfully." -ForegroundColor Green
} else {
    Write-Error "[FAIL] Verification script encountered errors (Exit code: $ExitCode)."
    exit $ExitCode
}
