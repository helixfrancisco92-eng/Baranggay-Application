<#
==============================================================================
CampusSafe (Group 7) — Archive Inspection Utility (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Target Database: grp07_campussafedb
Inspects the Table of Contents (TOC) of a pg_dump Custom Archive (-Fc)
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$BackupFile
)

$ErrorActionPreference = "Stop"

if (-not $BackupFile) {
    $backupDir = Join-Path $PSScriptRoot "..\backups"
    $BackupFile = Join-Path $backupDir "grp07_campussafedb_activity6.dump"
}

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " CampusSafe (Group 7) Archive TOC Inspection Utility             " -ForegroundColor Cyan
Write-Host " Target Archive: $BackupFile                                     " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

if (-not (Test-Path $BackupFile)) {
    Write-Error "[-] ERROR: Backup archive file not found: $BackupFile. Please execute 01_backup.ps1 first."
    exit 1
}

$pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
if (-not $pgRestoreCmd) {
    $commonPgPaths = @(
        "C:\Program Files\PostgreSQL\18\bin",
        "C:\Program Files\PostgreSQL\17\bin",
        "C:\Program Files\PostgreSQL\16\bin",
        "C:\Program Files\PostgreSQL\15\bin"
    )
    foreach ($p in $commonPgPaths) {
        if (Test-Path (Join-Path $p "pg_restore.exe")) {
            $env:PATH = "$p;$env:PATH"
            $pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $pgRestoreCmd) {
    Write-Error "[-] ERROR: pg_restore.exe was not found in PATH."
    exit 1
}

$tocOutput = [System.IO.Path]::ChangeExtension($BackupFile, ".toc.txt")
Write-Host "[1/3] Extracting archive Table of Contents (TOC) via pg_restore --list..." -ForegroundColor Yellow

$tocLines = & pg_restore.exe --list $BackupFile
$tocLines | Out-File -FilePath $tocOutput -Encoding utf8

$totalEntries = $tocLines.Count
$tableDataCount = ($tocLines | Select-String "TABLE DATA public ").Count
$indexCount = ($tocLines | Select-String "INDEX public ").Count
$seqCount = ($tocLines | Select-String "SEQUENCE ").Count
$fkCount = ($tocLines | Select-String "FK CONSTRAINT public ").Count
$checkCount = ($tocLines | Select-String "CHECK CONSTRAINT public ").Count

Write-Host "[2/3] Analyzing database object breakdown inside archive:" -ForegroundColor Yellow
Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray
Write-Host " Total Catalog TOC Items:     $totalEntries" -ForegroundColor White
Write-Host " User Table Data Blocks:      $tableDataCount / 9 expected" -ForegroundColor White
Write-Host " Performance B-Tree Indexes:  $indexCount / 10 expected (+ PK/Unique)" -ForegroundColor White
Write-Host " Auto-Increment Sequences:    $seqCount / 9 expected" -ForegroundColor White
Write-Host " Foreign Key Constraints:     $fkCount" -ForegroundColor White
Write-Host " Domain CHECK Constraints:    $checkCount" -ForegroundColor White
Write-Host "-----------------------------------------------------------------" -ForegroundColor Gray

Write-Host "[3/3] Previewing first 20 TOC catalog entries:" -ForegroundColor Yellow
$tocLines | Select-Object -First 20 | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

Write-Host ""
Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host "[+] Full Table of Contents exported to: $tocOutput" -ForegroundColor Green
Write-Host "=================================================================" -ForegroundColor Cyan

