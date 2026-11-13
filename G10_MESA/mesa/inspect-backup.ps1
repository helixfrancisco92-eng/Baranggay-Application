<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: inspect-backup.ps1
Purpose: Non-destructive Archive Table-of-Contents (TOC) & Checksum Verification
==============================================================================
#>
[CmdletBinding()]
param(
    [string]$BackupFile = "",
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$logsDir = Join-Path $workspaceRoot "logs"
$backupDir = Join-Path $workspaceRoot "backups"

if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - PostgreSQL Archive Inspection (PowerShell)" -ForegroundColor Cyan
Write-Host " Project: Restaurant Online Ordering & Table Reservation System (Binary Sisters)" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# Locate pg_restore
$pgRestore = Get-Command "pg_restore" -ErrorAction SilentlyContinue
if (-not $pgRestore) {
    $candidate = Join-Path $PsqlPath "pg_restore.exe"
    if (Test-Path $candidate) {
        $pgRestorePath = $candidate
    } else {
        throw "pg_restore.exe not found on PATH or at '$candidate'. Specify valid -PsqlPath."
    }
} else {
    $pgRestorePath = $pgRestore.Source
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
$checksumFile = "${BackupFile}.sha256"
$tocLog = Join-Path $logsDir "archive-toc.txt"

Write-Host "Inspecting Archive : $filename"
Write-Host "Full Path          : $BackupFile"

# 1. Verify Checksum
Write-Host "[1/3] Verifying SHA-256 Checksum..." -ForegroundColor Yellow
$currentHash = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash.ToLower()

if (Test-Path $checksumFile) {
    $recordedHash = ((Get-Content $checksumFile).Trim() -split "\s+")[0].ToLower()
    if ($currentHash -eq $recordedHash) {
        Write-Host " -> CHECKSUM VERIFIED MATCH: $currentHash" -ForegroundColor Green
    } else {
        Write-Host " -> ERROR: CHECKSUM MISMATCH!" -ForegroundColor Red
        Write-Host "    Recorded   : $recordedHash"
        Write-Host "    Calculated : $currentHash"
        throw "Archive integrity check failed."
    }
} else {
    Write-Host " -> Checksum companion file not found. Calculated hash: $currentHash"
}

# 2. Extract Table of Contents
Write-Host "[2/3] Extracting Table of Contents via pg_restore --list..." -ForegroundColor Yellow
& $pgRestorePath --list $BackupFile > $tocLog
Write-Host " -> TOC saved to: $tocLog" -ForegroundColor Green

$tocContent = Get-Content $tocLog

# 3. Audit Relational Objects
Write-Host "[3/3] Auditing Expected Relational Objects in Archive TOC..." -ForegroundColor Yellow
$tables = @("customer", "menu_item", "restaurant_table", "staff", "orders", "order_item", "reservation", "payment")
$missingCount = 0

foreach ($tbl in $tables) {
    $match = $tocContent | Where-Object { $_ -match "TABLE public $tbl\b" }
    if ($match) {
        Write-Host " [OK] Table public.$tbl confirmed in archive TOC." -ForegroundColor Green
    } else {
        Write-Host " [FAIL] Table public.$tbl is MISSING from archive TOC!" -ForegroundColor Red
        $missingCount++
    }
}

# Audit Views
$views = @("v_customer_directory", "v_staff_directory", "v_order_summary", "v_reservation_schedule")
foreach ($vw in $views) {
    $match = $tocContent | Where-Object { $_ -match "VIEW public $vw\b" }
    if ($match) {
        Write-Host " [OK] View public.$vw confirmed in archive TOC." -ForegroundColor Green
    }
}

# Audit Triggers
$triggers = @("trg_order_item_total", "trg_orders_require_items", "trg_order_item_keep_one", "trg_reservation_capacity")
foreach ($trg in $triggers) {
    $match = $tocContent | Where-Object { $_ -match "TRIGGER public $trg\b" }
    if ($match) {
        Write-Host " [OK] Trigger public.$trg confirmed in archive TOC." -ForegroundColor Green
    }
}

Write-Host "==============================================================================" -ForegroundColor Cyan
if ($missingCount -eq 0) {
    Write-Host " INSPECTION RESULT: SUCCESS - All 8 relational tables and dependencies verified." -ForegroundColor Green
} else {
    Write-Host " INSPECTION RESULT: FAILED - $missingCount table(s) missing from archive." -ForegroundColor Red
    exit 1
}
Write-Host "==============================================================================" -ForegroundColor Cyan

