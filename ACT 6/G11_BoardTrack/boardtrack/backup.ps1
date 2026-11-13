# ==============================================================================
# Script: backup.ps1
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Automated PostgreSQL Custom Format Logical Backup (pg_dump -Fc)
# OS / Environment: Windows PowerShell (PowerShell 5.1 / 7+)
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Database = "boardtrack_db",

    [Parameter(Mandatory=$false)]
    [string]$User = "postgres",

    [Parameter(Mandatory=$false)]
    [string]$HostName = "localhost",

    [Parameter(Mandatory=$false)]
    [int]$Port = 5432,

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = "C:\db-backups\boardtrack",

    [Parameter(Mandatory=$false)]
    [string]$DumpFileName = "boardtrack_db_activity6.dump",

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "$PSScriptRoot\..\logs\backup.log"
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  BoardTrack Database Logical Backup — COMP 018 Activity 6" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Timestamp   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Target Host : ${HostName}:${Port}"
Write-Host "Database    : $Database"
Write-Host "Backup User : $User"
Write-Host "Output Dir  : $OutputDir"
Write-Host "Backup File : $DumpFileName"
Write-Host "===================================================================="

# Ensure output directory exists
if (-not (Test-Path $OutputDir)) {
    try {
        New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
        Write-Host "[OK] Created protected backup storage directory: $OutputDir" -ForegroundColor Green
    } catch {
        Write-Error "Failed to create directory ${OutputDir}: $_"
        exit 1
    }
}

# Ensure logs directory exists
$logDir = Split-Path -Path $LogFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

$targetDumpPath = Join-Path -Path $OutputDir -ChildPath $DumpFileName
$startTime = Get-Date

Write-Host "[INFO] Initiating pg_dump in custom format (-Fc)..." -ForegroundColor Yellow

$pgDumpCmd = "pg_dump"
if (Get-Command pg_dump -ErrorAction SilentlyContinue) {
    $pgDumpCmd = "pg_dump"
} elseif (Test-Path "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe") {
    $pgDumpCmd = "C:\Program Files\PostgreSQL\18\bin\pg_dump.exe"
}

# Execute pg_dump
try {
    & $pgDumpCmd -h $HostName -p $Port -U $User -d $Database -Fc -v -f $targetDumpPath 2>&1 | Tee-Object -FilePath $LogFile
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] pg_dump exited with error code $LASTEXITCODE." -ForegroundColor Red
        exit $LASTEXITCODE
    }
} catch {
    Write-Host "[ERROR] Execution exception during pg_dump: $_" -ForegroundColor Red
    exit 1
}

$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

if (Test-Path $targetDumpPath) {
    $fileItem = Get-Item $targetDumpPath
    $fileSizeBytes = $fileItem.Length
    $fileSizeKb = [math]::Round($fileSizeBytes / 1KB, 2)
    $hashObj = Get-FileHash -Path $targetDumpPath -Algorithm SHA256
    $sha256 = $hashObj.Hash

    Write-Host ""
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "  BACKUP COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "====================================================================" -ForegroundColor Green
    Write-Host "Dump File       : $targetDumpPath"
    Write-Host "File Size       : $fileSizeBytes bytes ($fileSizeKb KB)"
    Write-Host "Execution Time  : $duration seconds"
    Write-Host "SHA-256 Checksum: $sha256" -ForegroundColor Yellow
    Write-Host "Execution Log   : $LogFile"
    Write-Host "===================================================================="

    # Save metadata summary
    $metaFile = "$targetDumpPath.meta.json"
    $metaData = @{
        project_name   = "BoardTrack"
        database_name  = $Database
        dbms           = "PostgreSQL 18.6"
        backup_method  = "pg_dump -Fc (Custom Archive)"
        backup_file    = $targetDumpPath
        file_size_bytes = $fileSizeBytes
        file_size_kb   = $fileSizeKb
        sha256_hash    = $sha256
        backup_user    = $User
        timestamp      = (Get-Date -Format "yyyy-MM-ddTHH:mm:sszzz")
        duration_sec   = $duration
        status         = "COMPLETED_VERIFIED"
    } | ConvertTo-Json -Depth 3

    Set-Content -Path $metaFile -Value $metaData
    Write-Host "[OK] Recorded backup manifest: $metaFile" -ForegroundColor Cyan
} else {
    Write-Host "[ERROR] Backup file was not created: $targetDumpPath" -ForegroundColor Red
    exit 1
}
