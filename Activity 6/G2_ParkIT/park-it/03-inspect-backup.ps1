<#
.SYNOPSIS
    COMP 018 — Database Administration (Activity 6: Part B)
    Script: 03-inspect-backup.ps1 (Windows Native PowerShell Companion)
    Purpose: Inspect PostgreSQL Custom-Format Archive TOC and Validate Checksum
    Platform: PostgreSQL 18.6 | Target DB: grp_parkitdb
#>

[CmdletBinding()]
param(
    [string]$TargetFile = ""
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "  PARK-IT DATABASE MANAGEMENT SYSTEM — ARCHIVE INSPECTION TOOL  " -ForegroundColor Cyan
Write-Host "  COMP 018 Database Administration (Activity 6: Part B - Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Blue

# Check pg_restore availability
$pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
if (-not $pgRestoreCmd) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin"
    if (Test-Path $standardPath) {
        $env:PATH = "$env:PATH;$standardPath"
        $pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
    }
}

if (-not $pgRestoreCmd) {
    Write-Error "[ERROR] pg_restore.exe was not found in PATH."
    exit 1
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupDir = Join-Path $scriptDir "..\backups"

# Locate backup
if ([string]::IsNullOrWhiteSpace($TargetFile)) {
    $canonical = Join-Path $backupDir "grp_parkitdb_activity6.dump"
    if (Test-Path $canonical) {
        $TargetFile = $canonical
    } elseif (Test-Path $backupDir) {
        $latest = Get-ChildItem -Path $backupDir -Filter "*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) { $TargetFile = $latest.FullName }
    }
}

if ([string]::IsNullOrWhiteSpace($TargetFile)) {
    $TargetFile = Read-Host "Enter path to backup archive (.dump)"
}

if (-not (Test-Path $TargetFile)) {
    Write-Error "[ERROR] Backup file does not exist: $TargetFile"
    exit 1
}

$fileItem = Get-Item $TargetFile
if ($fileItem.Length -eq 0) {
    Write-Error "[ERROR] Backup file is empty (0 bytes): $TargetFile"
    exit 1
}

$tocOutput = [System.IO.Path]::ChangeExtension($TargetFile, "txt")
$checksumPath = "${TargetFile}.sha256"

Write-Host "`n--- Inspecting Backup Archive ---" -ForegroundColor Blue
Write-Host "Archive Target   : $TargetFile" -ForegroundColor Cyan
Write-Host "File Size        : $($fileItem.Length) bytes" -ForegroundColor Cyan
Write-Host "Evidence TOC Log : $tocOutput" -ForegroundColor Cyan

# Checksum validation
Write-Host "`n--- Cryptographic Checksum Validation ---" -ForegroundColor Yellow
$currentHash = (Get-FileHash -Path $TargetFile -Algorithm SHA256).Hash.ToLower()
Write-Host "Computed SHA-256 : $currentHash" -ForegroundColor Cyan

if (Test-Path $checksumPath) {
    $expectedHash = (Get-Content $checksumPath -First 1).Split(" ", [System.StringSplitOptions]::RemoveEmptyEntries)[0].ToLower()
    Write-Host "Recorded SHA-256 : $expectedHash" -ForegroundColor Cyan
    if ($currentHash -eq $expectedHash) {
        Write-Host "[PASSED] Checksum integrity verified! File has not been modified or corrupted." -ForegroundColor Green
    } else {
        Write-Host "[FAILED] CHECKSUM MISMATCH! File may be corrupt or altered!" -ForegroundColor Red
        exit 1
    }
} else {
    Write-Host "[NOTICE] Checksum file '$checksumPath' not found; generated record." -ForegroundColor Yellow
    "$currentHash  $($fileItem.Name)" | Out-File -FilePath $checksumPath -Encoding ascii
}

# Extract Table of Contents
Write-Host "`n--- Extracting Archive Table of Contents (pg_restore --list) ---" -ForegroundColor Yellow
& pg_restore.exe --list $TargetFile > $tocOutput 2> "${TargetFile}.err.tmp"
$listExit = $LASTEXITCODE

if ($listExit -ne 0) {
    Write-Host "[ERROR] Failed to read archive TOC using pg_restore." -ForegroundColor Red
    if (Test-Path "${TargetFile}.err.tmp") { Get-Content "${TargetFile}.err.tmp" | Write-Host -ForegroundColor Red }
    exit $listExit
}
if (Test-Path "${TargetFile}.err.tmp") { Remove-Item "${TargetFile}.err.tmp" -Force }

Write-Host "[OK] TOC listing successfully exported to: $tocOutput" -ForegroundColor Green

# Object breakdown
Write-Host "`n================================================================" -ForegroundColor Blue
Write-Host "  PARK-IT DATABASE ARCHIVE OBJECT BREAKDOWN                     " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Blue

$tocLines = Get-Content $tocOutput

Write-Host "`n--- Verifying Core Park-It Entities in Archive ---" -ForegroundColor Yellow
$criticalTables = @("parking_zone", "vehicle", "staff_user", "transaction", "payment")
$allFound = $true

foreach ($tbl in $criticalTables) {
    $found = $tocLines | Where-Object { $_ -match "TABLE public $tbl " -or $_ -match "TABLE DATA public $tbl " }
    if ($found) {
        Write-Host "  [+] Entity '$tbl' : FOUND IN ARCHIVE" -ForegroundColor Green
    } else {
        Write-Host "  [-] Entity '$tbl' : MISSING FROM ARCHIVE" -ForegroundColor Red
        $allFound = $false
    }
}

if ($allFound) {
    Write-Host "`n[PASSED] All 5 core Park-It database entities are present in the backup archive." -ForegroundColor Green
} else {
    Write-Host "`n[WARNING] One or more core database tables are missing from the archive!" -ForegroundColor Red
}

Write-Host @"

================================================================================
CRITICAL DATABASE ADMINISTRATION INSIGHT:
WHY BACKUP EXISTENCE DOES NOT EQUAL RESTORABILITY
================================================================================
A backup is NOT verified until a full restoration drill has succeeded in an
isolated environment. 
Proceed to Part C: Isolated Restoration Test (04-restore-test.ps1 / .sh).
================================================================================
"@ -ForegroundColor Yellow

