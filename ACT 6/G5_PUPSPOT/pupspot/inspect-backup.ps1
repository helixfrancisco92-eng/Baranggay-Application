<#
==============================================================================
PUP-SPOT (Group 5) — Backup Archive Inspection Utility (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Target Database: grp05_lostandfounddb
Utility: pg_restore --list
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$BackupFile = "C:\Users\Lenovo\Downloads\backups\grp05_lostandfounddb_backup_20261112_235620.dump"
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " PUP-SPOT Backup Archive Inspector (pg_restore --list)           " -ForegroundColor Cyan
Write-Host " Course: COMP 018 Database Administration (Activity 6)           " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Check if backup file exists
if (-not (Test-Path $BackupFile)) {
    # Check default directory for most recent dump
    $dumpFiles = Get-ChildItem "C:\Users\Lenovo\Downloads\backups\*.dump" | Sort-Object LastWriteTime -Descending
    if ($dumpFiles.Count -gt 0) {
        $BackupFile = $dumpFiles[0].FullName
    } else {
        Write-Error "[ERROR] Backup file not found: $BackupFile"
        exit 1
    }
}

$fileItem = Get-Item $BackupFile
$sha256 = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash

Write-Host "`n[1/3] File Metadata Verification:" -ForegroundColor Yellow
Write-Host " Archive Path    : $($fileItem.FullName)"
Write-Host " Creation Time   : $($fileItem.CreationTime.ToString('yyyy-MM-dd HH:mm:ss'))"
Write-Host " File Size       : $($fileItem.Length) bytes ($([math]::Round($fileItem.Length/1KB, 2)) KB)"
Write-Host " SHA-256 Checksum: $sha256"

# 2. Check pg_restore tool
Write-Host "`n[2/3] Verifying pg_restore utility..." -ForegroundColor Yellow
$pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
if (-not $pgRestoreCmd) {
    $commonPgPaths = @("C:\Program Files\PostgreSQL\18\bin", "C:\Program Files\PostgreSQL\17\bin")
    foreach ($p in $commonPgPaths) {
        if (Test-Path "$p\pg_restore.exe") {
            $env:PATH = "$p;$env:PATH"
            $pgRestoreCmd = Get-Command pg_restore.exe -ErrorAction SilentlyContinue
            break
        }
    }
}

if (-not $pgRestoreCmd) {
    Write-Error "[FATAL] pg_restore.exe client tool not found."
    exit 1
}

# 3. Execute pg_restore --list
Write-Host "`n[3/3] Inspecting Table of Contents (TOC)..." -ForegroundColor Yellow
Write-Host " Executing: pg_restore --list `"$BackupFile`"" -ForegroundColor Gray
Write-Host "-----------------------------------------------------------------"

$tocOutput = & pg_restore --list $BackupFile 2>&1
$exitCode = $LASTEXITCODE

Write-Host ($tocOutput | Out-String)
Write-Host "-----------------------------------------------------------------"

if ($exitCode -eq 0) {
    Write-Host "[SUCCESS] Archive inspection completed successfully (Exit Code: 0)." -ForegroundColor Green
} else {
    Write-Error "[FAILED] pg_restore --list returned exit code: $exitCode"
    exit 1
}

