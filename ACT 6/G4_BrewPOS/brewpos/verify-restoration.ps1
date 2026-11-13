# ==============================================================================
# BrewPOS — Automated Restoration Verification Script (PowerShell)
# Course: COMP 018 — Database Administration (Activity 6)
# Target Database: grp_brewposdb_restore_test
# ==============================================================================

[CmdletBinding()]
param (
    [string]$EnvFile = "../configuration/.env",
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$TestDatabase = "grp_brewposdb_restore_test",
    [string]$Username = "postgres",
    [string]$SqlFile = "../sql/verification-queries.sql",
    [string]$ReportFile = "../reports/verification-execution-last.log"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS Database Restoration Verification Runner               " -ForegroundColor Cyan
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
                "RESTORE_TEST_DB" { $TestDatabase = $varVal }
                "DB_SUPERUSER"    { $Username = $varVal }
                "DB_PASSWORD"     { $env:PGPASSWORD = $varVal }
            }
        }
    }
}

# 2. Check for psql
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

if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
    Write-Error "[FATAL] 'psql' utility was not found in PATH."
    exit 1
}

# 3. Secure password prompt if needed
if (-not $env:PGPASSWORD) {
    $securePass = Read-Host "Enter password for PostgreSQL user '$Username'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

if (-not (Test-Path $SqlFile)) {
    Write-Error "[FATAL] Verification SQL file does not exist: $SqlFile"
    exit 1
}

Write-Host "[INFO] Executing verification queries on '$TestDatabase' ($HostName`:$Port)..." -ForegroundColor Yellow

$psqlArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-d", $TestDatabase,
    "-f", $SqlFile
)

$output = & psql @psqlArgs 2>&1
$exitCode = $LASTEXITCODE

# Save output to report log
$output | Set-Content -Path $ReportFile

Write-Host $output

if ($exitCode -ne 0) {
    Write-Error "[ERROR] Verification queries completed with errors (exit code $exitCode)."
    exit $exitCode
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] Verification queries executed successfully." -ForegroundColor Green
Write-Host " Log Saved: $ReportFile" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

