<#
.SYNOPSIS
    Inspects PostgreSQL Custom Archive (-Fc) backup files.
.DESCRIPTION
    Runs pg_restore --list to examine the Table of Contents (TOC) of a backup dump,
    verifying archive readability, header integrity, and cataloged database objects.
.NOTES
    Subject: COMP 018 – Database Administration (Activity 6)
#>

[CmdletBinding()]
param (
    [Parameter(Position = 0)]
    [string]$BackupFile
)

$ErrorActionPreference = "Stop"

Write-Host "=====================================================================" -ForegroundColor Cyan
Write-Host " COMP 018: Backup Archive Inspector (pg_restore --list)" -ForegroundColor Cyan
Write-Host "=====================================================================" -ForegroundColor Cyan

# 1. Resolve Backup File Path
if (-not $BackupFile) {
    # Find latest dump file in backups directory if not explicitly provided
    $DefaultBackupDir = "$PSScriptRoot\..\backups"
    if (Test-Path $DefaultBackupDir) {
        $LatestFile = Get-ChildItem -Path $DefaultBackupDir -Filter "*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($LatestFile) {
            $BackupFile = $LatestFile.FullName
        }
    }
}

if (-not $BackupFile -or -not (Test-Path $BackupFile)) {
    Write-Host "[NOTE] No explicit backup file provided. Testing against repository sample: 'Project-OJT-RMA-System/database/OJT Database.sql'" -ForegroundColor Yellow
    $RepoSample = "$PSScriptRoot\..\..\Project-OJT-RMA-System\database\OJT Database.sql"
    if (Test-Path $RepoSample) {
        $BackupFile = (Resolve-Path $RepoSample).Path
    } else {
        Write-Error "[FATAL] Please specify a valid backup file: -BackupFile <path_to_dump>"
        exit 1
    }
}

$FileInfo = Get-Item $BackupFile
Write-Host "[INFO] Inspecting Archive File: $($FileInfo.FullName)" -ForegroundColor White
Write-Host "[INFO] File Size: $($FileInfo.Length) bytes ($([Math]::Round($FileInfo.Length / 1KB, 2)) KB)" -ForegroundColor Gray

# 2. Check pg_restore availability
$PgRestore = (Get-Command pg_restore -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source -ErrorAction SilentlyContinue)
if (-not $PgRestore) {
    Write-Error "[FATAL] 'pg_restore' utility not found on PATH."
    exit 1
}

# 3. Compute Checksum
$Sha256 = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash
Write-Host "[INFO] SHA-256 Checksum: $Sha256" -ForegroundColor Gray

# 4. Execute pg_restore --list
Write-Host "`n[EXEC] Executing: pg_restore --list `"$($FileInfo.FullName)`"" -ForegroundColor Cyan
$TocOutput = & $PgRestore --list $FileInfo.FullName 2>&1
$ExitCode = $LASTEXITCODE

if ($ExitCode -eq 0) {
    Write-Host "`n=====================================================================" -ForegroundColor Green
    Write-Host " ARCHIVE INSPECTION COMPLETED SUCCESSFULLY" -ForegroundColor Green
    Write-Host "=====================================================================" -ForegroundColor Green
    
    # Analyze TOC entries
    $TocLines = $TocOutput | Where-Object { $_ -and -not $_.StartsWith(";") }
    $TableEntries = $TocLines | Where-Object { $_ -match "\bTABLE\b" -and $_ -notmatch "\bTABLE DATA\b" }
    $ConstraintEntries = $TocLines | Where-Object { $_ -match "\bCONSTRAINT\b|\bFK CONSTRAINT\b|\bCHECK CONSTRAINT\b" }
    $AclEntries = $TocLines | Where-Object { $_ -match "\bACL\b" }

    Write-Host "Total TOC Entries Found: $($TocLines.Count)" -ForegroundColor White
    Write-Host "Tables Identified       : $($TableEntries.Count)" -ForegroundColor White
    Write-Host "Constraints Identified  : $($ConstraintEntries.Count)" -ForegroundColor White
    Write-Host "Access Control (ACL)    : $($AclEntries.Count)" -ForegroundColor White

    Write-Host "`n--- Summary of Table Objects in Archive ---" -ForegroundColor Yellow
    $TableEntries | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }

    Write-Host "`n--- Raw Header and Sample TOC Entries ---" -ForegroundColor White
    $TocOutput | Select-Object -First 35 | ForEach-Object { Write-Host $_ -ForegroundColor DarkGray }

} else {
    Write-Error "[FAIL] pg_restore failed to read archive header (Exit code: $ExitCode). Output: $TocOutput"
    exit 1
}
