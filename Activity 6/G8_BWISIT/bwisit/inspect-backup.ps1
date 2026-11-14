<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: inspect-backup.ps1
Purpose: Inspect Table-of-Contents (TOC) of PostgreSQL custom dump archive
Utility: pg_restore --list
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

# Locate dump file
if ([string]::IsNullOrWhiteSpace($BackupFile)) {
    $latest = Get-ChildItem -Path $backupDir -Filter "*.dump" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) {
        $BackupFile = $latest.FullName
    } else {
        throw "No .dump file found in '$backupDir'. Provide path with -BackupFile."
    }
}

if (-not (Test-Path $BackupFile)) {
    throw "Backup file '$BackupFile' does not exist."
}

# Locate pg_restore
$pgRestore = Get-Command "pg_restore" -ErrorAction SilentlyContinue
if (-not $pgRestore) {
    $candidate = Join-Path $PsqlPath "pg_restore.exe"
    if (Test-Path $candidate) {
        $pgRestorePath = $candidate
    } else {
        throw "pg_restore.exe not found on PATH or at '$candidate'."
    }
} else {
    $pgRestorePath = $pgRestore.Source
}

$tocLog = Join-Path $logsDir "archive-toc.txt"
$inspectLog = Join-Path $logsDir "inspect-backup.log"

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - PostgreSQL Archive Inspection & TOC Verification" -ForegroundColor Cyan
Write-Host " Target Archive: $BackupFile" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# Validate SHA-256
$checksumFile = "${BackupFile}.sha256"
if (Test-Path $checksumFile) {
    $recorded = ((Get-Content $checksumFile) -split '\s+')[0].Trim().ToLower()
    $computed = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash.ToLower()
    if ($recorded -eq $computed) {
        Write-Host "[OK] SHA-256 Checksum verified: $computed matches recorded hash." -ForegroundColor Green
    } else {
        Write-Warning "SHA-256 Checksum MISMATCH! Recorded: $recorded, Computed: $computed"
    }
}

Write-Host "Extracting Table of Contents (TOC) using pg_restore --list..." -ForegroundColor Yellow
& $pgRestorePath --list $BackupFile | Set-Content -Path $tocLog -Encoding utf8
if ($LASTEXITCODE -ne 0) {
    throw "pg_restore --list failed with exit code $LASTEXITCODE."
}

$tocLines = Get-Content $tocLog
Write-Host "[OK] TOC extracted successfully: $($tocLines.Count) entries documented in '$tocLog'." -ForegroundColor Green

Write-Host "------------------------------------------------------------------------------"
Write-Host " AUDITING CRITICAL CAMPUS CANTEEN OBJECTS IN ARCHIVE"
Write-Host "------------------------------------------------------------------------------"

$expectedTables = @("student", "vendor", "menu_item", "customer_order", "order_item", "queue_entry", "notification")
$missingCount = 0

foreach ($tbl in $expectedTables) {
    $match = $tocLines | Where-Object { $_ -match "TABLE (DATA )?public $tbl " }
    if ($match) {
        Write-Host "  [FOUND] Table: public.$tbl" -ForegroundColor Green
    } else {
        Write-Host "  [MISSING] Table: public.$tbl" -ForegroundColor Red
        $missingCount++
    }
}

if ($missingCount -eq 0) {
    Write-Host "[PASS] All 7 Campus Canteen core relational tables confirmed in dump archive." -ForegroundColor Green
} else {
    Write-Warning "$missingCount expected tables were not found in archive TOC."
}

$inspectEntry = @"
--------------------------------------------------------------------------------
Inspection Executed : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Archive File        : $BackupFile
Total TOC Objects   : $($tocLines.Count)
Missing Core Tables : $missingCount
TOC File Saved To   : $tocLog
--------------------------------------------------------------------------------
"@
Add-Content -Path $inspectLog -Value $inspectEntry

Write-Host "==============================================================================" -ForegroundColor DarkCyan
Write-Host " WHY ARCHIVE INSPECTION IS ESSENTIAL (TECHNICAL DBA PRINCIPLE):" -ForegroundColor DarkCyan
Write-Host " Simply checking that a backup file exists on disk does NOT guarantee that"
Write-Host " the file contains a valid, readable, or restorable database. Zero-byte files,"
Write-Host " truncated streams, corrupted blocks, missing dependencies, or incompatible"
Write-Host " encoding can result in a file being present while restoration fails completely."
Write-Host " Inspecting the TOC with pg_restore --list proves archive structure and integrity"
Write-Host " before committing to a restore operation."
Write-Host "==============================================================================" -ForegroundColor DarkCyan

