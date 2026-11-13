# ==============================================================================
# BrewPOS — Backup Archive Inspection Script (PowerShell)
# Course: COMP 018 — Database Administration (Activity 6)
# Utility: pg_restore --list
# ==============================================================================

[CmdletBinding()]
param (
    [Parameter(Mandatory=$false)]
    [string]$BackupFile = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " BrewPOS Backup Inspection Utility (pg_restore --list)          " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Resolve backup file
if (-not $BackupFile) {
    $dumpFiles = Get-ChildItem -Path "../backups" -Filter "*.dump" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending
    if ($dumpFiles -and $dumpFiles.Count -gt 0) {
        $BackupFile = $dumpFiles[0].FullName
        Write-Host "[INFO] Auto-selected most recent backup archive: $BackupFile" -ForegroundColor Yellow
    } else {
        Write-Error "[FATAL] No backup file specified and no .dump file found in ../backups."
        exit 1
    }
}

if (-not (Test-Path $BackupFile)) {
    Write-Error "[FATAL] Specified backup file does not exist: $BackupFile"
    exit 1
}

# 2. Check for pg_restore utility
if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin"
    )
    foreach ($p in $commonPgPaths) {
        if (Test-Path "$p\pg_restore.exe") {
            $env:Path += ";$p"
            break
        }
    }
}

if (-not (Get-Command pg_restore -ErrorAction SilentlyContinue)) {
    Write-Error "[FATAL] 'pg_restore' utility was not found in PATH."
    exit 1
}

# 3. Inspect File Properties
$item = Get-Item $BackupFile
$sizeKB = [math]::Round($item.Length / 1024, 2)
$hash = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash

Write-Host "File Details:" -ForegroundColor Gray
Write-Host "  Path:        $($item.FullName)" -ForegroundColor White
Write-Host "  Size:        $sizeKB KB ($($item.Length) bytes)" -ForegroundColor White
Write-Host "  Modified:    $($item.LastWriteTime)" -ForegroundColor White
Write-Host "  SHA-256:     $hash" -ForegroundColor White
Write-Host ""

# 4. Execute pg_restore --list
Write-Host "[INSPECTING] Reading Table of Contents (TOC) with pg_restore --list..." -ForegroundColor Yellow
$tocOutput = & pg_restore --list $BackupFile
$exitCode = $LASTEXITCODE

if ($exitCode -ne 0) {
    Write-Error "[ERROR] pg_restore failed to read backup file (exit code $exitCode). Archive may be corrupt."
    exit $exitCode
}

# 5. Verify presence of expected BrewPOS objects
$expectedTables = @("staff", "menu_category", "menu_item", "order_ticket", "order_line_item")
$foundTables = @()
$missingTables = @()

foreach ($tbl in $expectedTables) {
    $pattern = "TABLE DATA public $tbl "
    if ($tocOutput | Select-String -SimpleMatch $pattern) {
        $foundTables += $tbl
    } else {
        # Check if table DDL definition is at least present
        $ddlPattern = "TABLE public $tbl "
        if ($tocOutput | Select-String -SimpleMatch $ddlPattern) {
            $foundTables += $tbl
        } else {
            $missingTables += $tbl
        }
    }
}

Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
Write-Host "Archive Table Verification:" -ForegroundColor Yellow
foreach ($tbl in $foundTables) {
    Write-Host "  [OK] Found table: public.$tbl" -ForegroundColor Green
}
foreach ($tbl in $missingTables) {
    Write-Host "  [FAIL] Missing expected table: public.$tbl" -ForegroundColor Red
}

# Check for custom performance indexes
$hasIdxTicket = [bool]($tocOutput | Select-String -SimpleMatch "idx_order_ticket_timestamp")
$hasIdxLineItem = [bool]($tocOutput | Select-String -SimpleMatch "idx_order_line_item_item_id")

Write-Host ""
Write-Host "Performance Index Verification:" -ForegroundColor Yellow
if ($hasIdxTicket) { Write-Host "  [OK] Found index: idx_order_ticket_timestamp" -ForegroundColor Green }
else { Write-Host "  [WARN] Index idx_order_ticket_timestamp not found in TOC" -ForegroundColor Yellow }

if ($hasIdxLineItem) { Write-Host "  [OK] Found index: idx_order_line_item_item_id" -ForegroundColor Green }
else { Write-Host "  [WARN] Index idx_order_line_item_item_id not found in TOC" -ForegroundColor Yellow }

Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
if ($missingTables.Count -eq 0) {
    Write-Host " [SUCCESS] Archive TOC is intact and contains all 5 expected BrewPOS tables." -ForegroundColor Green
} else {
    Write-Host " [WARNING] Some expected tables were not detected in archive TOC." -ForegroundColor Red
}
Write-Host "=================================================================" -ForegroundColor Cyan

