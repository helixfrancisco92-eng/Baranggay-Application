<#
==============================================================================
HabalGo (Group 6) — Backup Archive Inspection Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6)
Utility: pg_restore --list
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$BackupFilePath = ""
)

$ErrorActionPreference = "Stop"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " HabalGo Backup Archive Table of Contents (TOC) Inspection       " -ForegroundColor Cyan
Write-Host " Utility: pg_restore --list                                      " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Locate Archive File
if (-not $BackupFilePath) {
    $backupDir = Join-Path $PSScriptRoot "..\backups"
    if (Test-Path $backupDir) {
        $latest = Get-ChildItem -Path $backupDir -Filter "*activity6*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($latest) {
            $BackupFilePath = $latest.FullName
        }
    }
}

if (-not $BackupFilePath -or (-not (Test-Path $BackupFilePath))) {
    Write-Error "[ERROR] No valid backup archive (.dump) found. Please supply a valid path via -BackupFilePath."
    exit 1
}

$fileItem = Get-Item $BackupFilePath
Write-Host "[1/4] Target Archive: $($fileItem.Name)" -ForegroundColor Green
Write-Host "      Archive Path  : $($fileItem.FullName)"
Write-Host "      Archive Size  : $($fileItem.Length) bytes ($([math]::Round($fileItem.Length/1KB, 2)) KB)"

# 2. Check Cryptographic Checksum
$checksumFile = "${BackupFilePath}.sha256"
Write-Host "[2/4] Verifying SHA-256 Checksum..." -ForegroundColor Yellow
$computedHash = (Get-FileHash -Path $BackupFilePath -Algorithm SHA256).Hash
Write-Host "      Computed SHA-256: $computedHash"

if (Test-Path $checksumFile) {
    $manifestContent = (Get-Content $checksumFile).Trim()
    $storedHash = ($manifestContent -split '\s+')[0]
    if ($computedHash.ToUpper() -eq $storedHash.ToUpper()) {
        Write-Host "      Checksum Match   : VERIFIED (Archive hash strictly matches manifest)" -ForegroundColor Green
    } else {
        Write-Warning "      [MISMATCH] Archive checksum does NOT match manifest! Stored: $storedHash vs Computed: $computedHash"
    }
} else {
    Write-Host "      Notice: No .sha256 manifest file found alongside archive." -ForegroundColor DarkGray
}

# 3. Parse Table of Contents using pg_restore --list
Write-Host "[3/4] Parsing Archive Table of Contents (TOC) via pg_restore --list..." -ForegroundColor Yellow
$tocLines = & pg_restore --list $BackupFilePath 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FAILED] pg_restore --list failed with exit code $LASTEXITCODE. Output: $tocLines"
    exit 1
}

$tables = @()
$sequences = @()
$indexes = @()
$constraints = @()

foreach ($line in $tocLines) {
    if ($line -match "^\d+;\s+\d+\s+\d+\s+TABLE\s+(\w+)\s+(\w+)") {
        $tables += "$($Matches[1]).$($Matches[2])"
    }
    elseif ($line -match "^\d+;\s+\d+\s+\d+\s+SEQUENCE\s+(\w+)\s+(\w+)") {
        $sequences += "$($Matches[1]).$($Matches[2])"
    }
    elseif ($line -match "^\d+;\s+\d+\s+\d+\s+INDEX\s+(\w+)\s+(\w+)") {
        $indexes += "$($Matches[1]).$($Matches[2])"
    }
    elseif ($line -match "^\d+;\s+\d+\s+\d+\s+CONSTRAINT\s+(\w+)\s+(\w+)") {
        $constraints += "$($Matches[1]).$($Matches[2])"
    }
}

Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
Write-Host " ARCHIVE TOC CONTENT SUMMARY                                     " -ForegroundColor Green
Write-Host "-----------------------------------------------------------------" -ForegroundColor Green
Write-Host " Total Objects Identified : $($tocLines.Count) entries"
Write-Host " Discovered Tables ($($tables.Count)):"
$tables | ForEach-Object { Write-Host "   - $_" -ForegroundColor Cyan }
Write-Host " Discovered Sequences ($($sequences.Count)):"
$sequences | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
Write-Host " Discovered Indexes ($($indexes.Count)):"
$indexes | ForEach-Object { Write-Host "   - $_" -ForegroundColor Gray }
Write-Host "-----------------------------------------------------------------" -ForegroundColor Green

# 4. Educational Explanation
Write-Host "[4/4] ARCHIVE AUDIT EVALUATION:" -ForegroundColor Yellow
Write-Host @"
=================================================================
WHAT TOC INSPECTION PROVES:
1. The backup file is a valid, uncorrupted PostgreSQL custom-format archive.
2. The archive header and table of contents are readable and syntactically sound.
3. The listed database objects (schemas, tables, sequences, indexes, and ACLs)
   were successfully captured by pg_dump at the time of backup.

WHAT TOC INSPECTION DOES NOT PROVE (Why restore testing is mandatory):
1. It does NOT prove that table rows or data blocks are free from storage corruption.
2. It does NOT prove that foreign key constraints can be satisfied upon restoration.
3. It does NOT prove that target database roles, users, and permissions exist.
4. It does NOT prove that the application can successfully connect and execute queries.
5. True database recoverability can ONLY be established through successful restoration
   and semantic verification in an isolated test database.
=================================================================
"@ -ForegroundColor DarkCyan

