<#
.SYNOPSIS
    Automated PostgreSQL Database Backup Script for Project OJT RMA System.
.DESCRIPTION
    Creates a secure, verified logical backup using pg_dump in Custom format (-Fc).
    Computes SHA-256 checksum, logs metadata, and validates file integrity.
.NOTES
    Subject: COMP 018 – Database Administration (Activity 6)
#>

[CmdletBinding()]
param (
    [string]$EnvFile = "$PSScriptRoot\..\configuration\.env",
    [string]$TargetDatabase,
    [string]$OutputDir
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " COMP 018: Database Backup Generator (Project OJT RMA System)" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Load configuration from .env if present
$Config = @{
    DB_HOST     = "localhost"
    DB_PORT     = "5432"
    DB_NAME     = "ojt_management"
    DB_USER     = "postgres"
    BACKUP_DIR  = "$PSScriptRoot\..\backups"
}

if (Test-Path $EnvFile) {
    Write-Host "[INFO] Loading configuration from: $EnvFile" -ForegroundColor Gray
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
} else {
    Write-Host "[WARN] Configuration file not found at $EnvFile. Using defaults and environment variables." -ForegroundColor Yellow
}

# Override from command line parameters if provided
if ($TargetDatabase) { $Config["DB_NAME"] = $TargetDatabase }
if ($OutputDir) { $Config["BACKUP_DIR"] = $OutputDir }

# 2. Verify pg_dump utility is available
$PgDumpPath = (Get-Command pg_dump -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if (-not $PgDumpPath) {
    Write-Error "[FATAL] 'pg_dump' utility was not found on PATH. Ensure PostgreSQL client tools are installed."
    exit 1
}
Write-Host "[OK] Detected pg_dump: $PgDumpPath" -ForegroundColor Green

# 3. Securely handle credentials (PGPASSWORD / Prompt)
$DbUser = $Config["DB_USER"]
$DbHost = $Config["DB_HOST"]
$DbPort = $Config["DB_PORT"]
$DbName = $Config["DB_NAME"]
$BackupDir = [System.IO.Path]::GetFullPath($Config["BACKUP_DIR"])

if (-not (Test-Path $BackupDir)) {
    Write-Host "[INFO] Creating backup directory: $BackupDir" -ForegroundColor Gray
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
}

$Timestamp = (Get-Date).ToString("yyyyMMdd_HHmmss")
$BackupFileName = "${DbName}_backup_${Timestamp}.dump"
$BackupFilePath = Join-Path $BackupDir $BackupFileName

Write-Host "`n--- Backup Parameters ---" -ForegroundColor White
Write-Host "Target Database : $DbName"
Write-Host "Host / Port     : ${DbHost}:${DbPort}"
Write-Host "Database User   : $DbUser"
Write-Host "Output File     : $BackupFilePath"
Write-Host "Backup Format   : Custom Archive (-Fc, compressed)"
Write-Host "------------------------`n"

# 4. Check Database Reachability (non-destructive check)
Write-Host "[INFO] Checking PostgreSQL connectivity..." -ForegroundColor Gray
$PsqlCmd = (Get-Command psql -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if ($PsqlCmd) {
    & $PsqlCmd -U $DbUser -h $DbHost -p $DbPort -d $DbName -c "SELECT current_database(), current_user;" -w 2>$null
    if ($LASTEXITCODE -ne 0 -and -not $env:PGPASSWORD -and -not $Config["DB_PASSWORD"]) {
        Write-Host "[NOTE] Password required to connect. You will be prompted by pg_dump or provide PGPASSWORD." -ForegroundColor Yellow
    }
}

if ($Config["DB_PASSWORD"]) {
    $env:PGPASSWORD = $Config["DB_PASSWORD"]
}

# 5. Execute pg_dump
$StartTime = Get-Date
Write-Host "[EXEC] Starting pg_dump execution at $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')..." -ForegroundColor Cyan

try {
    & pg_dump -U $DbUser -h $DbHost -p $DbPort -Fc -d $DbName -f $BackupFilePath
    $ExitCode = $LASTEXITCODE
} catch {
    $ExitCode = 1
    Write-Error "[ERROR] Execution exception during pg_dump: $_"
}

# 6. Verify Backup Output
if ($ExitCode -eq 0 -and (Test-Path $BackupFilePath)) {
    $FileInfo = Get-Item $BackupFilePath
    if ($FileInfo.Length -gt 0) {
        $Duration = (Get-Date) - $StartTime
        $Sha256 = (Get-FileHash -Path $BackupFilePath -Algorithm SHA256).Hash

        Write-Host "`n=====================================================================" -ForegroundColor Green
        Write-Host " BACKUP COMPLETED AND VERIFIED SUCCESSFULLY" -ForegroundColor Green
        Write-Host "=====================================================================" -ForegroundColor Green
        Write-Host "Backup File      : $($FileInfo.FullName)"
        Write-Host "Creation Time    : $($FileInfo.CreationTime)"
        Write-Host "File Size        : $($FileInfo.Length) bytes ($([Math]::Round($FileInfo.Length / 1KB, 2)) KB)"
        Write-Host "Duration         : $($Duration.TotalSeconds) seconds"
        Write-Host "SHA-256 Checksum : $Sha256"
        Write-Host "Exit Code        : $ExitCode"
        Write-Host "=====================================================================`n"

        # Write metadata companion log
        $MetaFile = "$BackupFilePath.meta.json"
        $MetaObj = @{
            database         = $DbName
            host             = $DbHost
            port             = $DbPort
            user             = $DbUser
            backup_file      = $BackupFileName
            timestamp        = (Get-Date -Format "o")
            file_size_bytes  = $FileInfo.Length
            sha256_checksum  = $Sha256
            format           = "PostgreSQL Custom (-Fc)"
            pg_dump_version  = (& pg_dump --version)
        }
        $MetaObj | ConvertTo-Json -Depth 3 | Set-Content -Path $MetaFile -Encoding utf8
        Write-Host "[INFO] Metadata recorded to: $MetaFile" -ForegroundColor Gray
    } else {
        Write-Error "[FAIL] Backup file was created but has 0 bytes length."
        exit 1
    }
} else {
    Write-Error "[FAIL] pg_dump failed with exit code $ExitCode. Backup file was not created or is invalid."
    exit 1
}
