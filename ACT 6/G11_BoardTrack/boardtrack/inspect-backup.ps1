# ==============================================================================
# Script: inspect-backup.ps1
# System: BoardTrack — Boarding House & Rental Management System
# Purpose: Inspect Table-of-Contents (TOC) of PostgreSQL custom dump archive
# OS / Environment: Windows PowerShell
# ==============================================================================

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$DumpPath = "C:\db-backups\boardtrack\boardtrack_db_activity6.dump",

    [Parameter(Mandatory=$false)]
    [string]$LogFile = "$PSScriptRoot\..\logs\inspect-backup.log"
)

$ErrorActionPreference = "Stop"

Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "  BoardTrack Backup Archive TOC Inspection — COMP 018 Activity 6" -ForegroundColor Cyan
Write-Host "====================================================================" -ForegroundColor Cyan
Write-Host "Timestamp   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "Target Dump : $DumpPath"
Write-Host "===================================================================="

if (-not (Test-Path $DumpPath)) {
    Write-Host "[ERROR] Target dump file not found at: $DumpPath" -ForegroundColor Red
    Write-Host "[INFO] Please provide an existing backup file or execute backup.ps1 first." -ForegroundColor Yellow
    exit 1
}

# Verify checksum
$hashObj = Get-FileHash -Path $DumpPath -Algorithm SHA256
Write-Host "[INFO] SHA-256 Hash of Archive: $($hashObj.Hash)" -ForegroundColor Yellow

$metaFile = "$DumpPath.meta.json"
if (Test-Path $metaFile) {
    $meta = Get-Content $metaFile | ConvertFrom-Json
    if ($meta.sha256_hash -eq $hashObj.Hash) {
        Write-Host "[OK] Integrity verified: Checksum matches creation manifest!" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Checksum MISMATCH with creation manifest!" -ForegroundColor Red
    }
}

# Ensure logs dir exists
$logDir = Split-Path -Path $LogFile -Parent
if (-not (Test-Path $logDir)) { New-Item -ItemType Directory -Path $logDir -Force | Out-Null }

$pgRestoreCmd = "pg_restore"
if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
    if (Test-Path "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe") {
        $pgRestoreCmd = "C:\Program Files\PostgreSQL\18\bin\pg_restore.exe"
    }
}

Write-Host "[INFO] Extracting Table-of-Contents (pg_restore --list)..." -ForegroundColor Yellow

$tocOutput = & $pgRestoreCmd --list $DumpPath 2>&1
$tocOutput | Set-Content -Path $LogFile

$expectedTables = @('property', 'room', 'tenant', 'lease', 'payment', 'utility_bill', 'app_user', 'schema_migrations')
$expectedViews = @('v_lease_summary')
$expectedTriggers = @('trg_lease_sync_room', 'trg_room_status_guard')
$expectedFunctions = @('sync_room_status', 'guard_room_status')

Write-Host ""
Write-Host "--- Schema Object Audit from Backup TOC ---" -ForegroundColor Cyan
$missingCount = 0

foreach ($tbl in $expectedTables) {
    $match = $tocOutput | Where-Object { $_ -match "TABLE\s+public\s+$tbl\s" }
    if ($match) {
        Write-Host "  [FOUND] TABLE: $tbl" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] TABLE: $tbl" -ForegroundColor Red
        $missingCount++
    }
}

foreach ($vw in $expectedViews) {
    $match = $tocOutput | Where-Object { $_ -match "VIEW\s+public\s+$vw\s" }
    if ($match) {
        Write-Host "  [FOUND] VIEW: $vw" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] VIEW: $vw" -ForegroundColor Red
        $missingCount++
    }
}

foreach ($fn in $expectedFunctions) {
    $match = $tocOutput | Where-Object { $_ -match "FUNCTION\s+public\s+$fn" }
    if ($match) {
        Write-Host "  [FOUND] FUNCTION: $fn" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] FUNCTION: $fn" -ForegroundColor Red
        $missingCount++
    }
}

foreach ($trg in $expectedTriggers) {
    $match = $tocOutput | Where-Object { $_ -match "TRIGGER\s+public\s+.*$trg" }
    if ($match) {
        Write-Host "  [FOUND] TRIGGER: $trg" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] TRIGGER: $trg" -ForegroundColor Red
        $missingCount++
    }
}

Write-Host "===================================================================="
if ($missingCount -eq 0) {
    Write-Host "[SUCCESS] Archive TOC verified: All core tables, views, functions, and triggers are present!" -ForegroundColor Green
} else {
    Write-Host "[WARNING] Archive TOC has $missingCount missing objects. Check $LogFile for details." -ForegroundColor Yellow
}
Write-Host "TOC Listing recorded to: $LogFile" -ForegroundColor Cyan
Write-Host "===================================================================="

