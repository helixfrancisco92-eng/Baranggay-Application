# ==============================================================================
# BrewPOS — Automated Database Backup Script (PowerShell)
# Course: COMP 018 — Database Administration (Activity 6)
# Database Engine: PostgreSQL 18.6 / 16+
# Target Database: grp_brewposdb
# ==============================================================================

[CmdletBinding()]
param (
    [string]$EnvFile = "../configuration/.env",
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$Database = "grp_brewposdb",
    [string]$Username = "postgres",
    [string]$BackupDirectory = "../backups"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS Database Backup Utility (PostgreSQL pg_dump -Fc)       " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Load configuration securely from .env if available
if (Test-Path $EnvFile) {
    Write-Host "[INFO] Loading configuration from $EnvFile..." -ForegroundColor Gray
    Get-Content $EnvFile | ForEach-Object {
        $line = $_.Trim()
        if ($line -and -not $line.StartsWith("#") -and $line.Contains("=")) {
            $parts = $line.Split("=", 2)
            $varName = $parts[0].Trim()
            $varVal = $parts[1].Trim()
            switch ($varName) {
                "DB_HOST"      { $HostName = $varVal }
                "DB_PORT"      { $Port = $varVal }
                "DB_NAME"      { $Database = $varVal }
                "DB_SUPERUSER" { $Username = $varVal }
                "BACKUP_DIR"   { $BackupDirectory = $varVal }
                "DB_PASSWORD"  { $env:PGPASSWORD = $varVal }
            }
        }
    }
}

# 2. Check for required database utility: pg_dump
Write-Host "[1/6] Verifying pg_dump utility installation..." -ForegroundColor Yellow
if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
    # Attempt common PostgreSQL installation paths on Windows
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin"
    )
    foreach ($p in $commonPgPaths) {
        if (Test-Path "$p\pg_dump.exe") {
            $env:Path += ";$p"
            break
        }
    }
}

if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
    Write-Error "[FATAL] 'pg_dump' utility was not found in PATH or standard installation directories. Please install PostgreSQL or add its bin directory to PATH."
    exit 1
}
$pgDumpVersion = (pg_dump --version)
Write-Host "      Detected utility: $pgDumpVersion" -ForegroundColor Green

# 3. Prompt for password securely if not provided in environment
if (-not $env:PGPASSWORD) {
    Write-Host "[INFO] Password not detected in environment." -ForegroundColor Gray
    $securePass = Read-Host "Enter password for PostgreSQL user '$Username'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# 4. Verify / create backup destination directory
Write-Host "[2/6] Verifying backup destination directory..." -ForegroundColor Yellow
if (-not (Test-Path $BackupDirectory)) {
    New-Item -ItemType Directory -Path $BackupDirectory -Force | Out-Null
    Write-Host "      Created directory: $(Resolve-Path $BackupDirectory)" -ForegroundColor Gray
} else {
    Write-Host "      Destination exists: $(Resolve-Path $BackupDirectory)" -ForegroundColor Gray
}

# 5. Generate timestamped backup filename
$timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$backupFilename = "brewpos_${Database}_${timestamp}.dump"
$backupFilePath = Join-Path $BackupDirectory $backupFilename

Write-Host "[3/6] Target Database: $Database on ${HostName}:${Port}" -ForegroundColor Gray
Write-Host "      Output File:     $backupFilePath" -ForegroundColor Gray

# 6. Execute pg_dump command using custom format (-Fc)
Write-Host "[4/6] Executing logical backup (pg_dump -Fc)..." -ForegroundColor Yellow
$dumpArgs = @(
    "-U", $Username,
    "-h", $HostName,
    "-p", $Port,
    "-Fc",
    "-v",
    "-d", $Database,
    "-f", $backupFilePath
)

try {
    & pg_dump @dumpArgs
    $dumpExitCode = $LASTEXITCODE
} catch {
    Write-Error "[FATAL] Backup execution failed: $_"
    exit 1
}

if ($dumpExitCode -ne 0) {
    Write-Error "[ERROR] pg_dump exited with error code $dumpExitCode."
    exit $dumpExitCode
}

# 7. Confirm file existence and verify size
Write-Host "[5/6] Validating generated backup file..." -ForegroundColor Yellow
if (-not (Test-Path $backupFilePath)) {
    Write-Error "[ERROR] Backup file was not created at expected path: $backupFilePath"
    exit 1
}

$fileItem = Get-Item $backupFilePath
$fileSizeBytes = $fileItem.Length
$fileSizeKB = [math]::Round($fileSizeBytes / 1024, 2)

if ($fileSizeBytes -le 0) {
    Write-Error "[ERROR] Backup file exists but is empty (0 bytes). Backup aborted."
    exit 1
}
Write-Host "      File exists and is non-empty: $fileSizeKB KB ($fileSizeBytes bytes)" -ForegroundColor Green

# 8. Compute SHA-256 checksum
Write-Host "[6/6] Computing cryptographic SHA-256 checksum..." -ForegroundColor Yellow
$checksumObj = Get-FileHash -Path $backupFilePath -Algorithm SHA256
$checksum = $checksumObj.Hash
Write-Host "      SHA-256: $checksum" -ForegroundColor Green

# 9. Output Summary Log
$summaryFile = Join-Path $BackupDirectory "backup-manifest-${timestamp}.json"
$summaryObj = [PSCustomObject]@{
    DatabaseName   = $Database
    Host           = $HostName
    Port           = $Port
    User           = $Username
    BackupFile     = $backupFilename
    FullPath       = (Resolve-Path $backupFilePath).Path
    SizeBytes      = $fileSizeBytes
    SizeKB         = $fileSizeKB
    SHA256         = $checksum
    TimestampUTC   = (Get-Date).ToUniversalTime().ToString("o")
    PostgresVersion = $pgDumpVersion
}
$summaryObj | ConvertTo-Json -Depth 3 | Set-Content -Path $summaryFile

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " [SUCCESS] BrewPOS Backup Completed Successfully!" -ForegroundColor Green
Write-Host " Backup Archive: $backupFilePath" -ForegroundColor Cyan
Write-Host " Checksum (SHA-256): $checksum" -ForegroundColor Cyan
Write-Host " Manifest Saved: $summaryFile" -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

