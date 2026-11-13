<#
.SYNOPSIS
    COMP 018 — Database Administration (Activity 6: Part B)
    Script: 02-backup.ps1 (Windows Native PowerShell Companion)
    Purpose: Interactive, secure custom-format backup generator for Park-It DBMS
    Platform: PostgreSQL 18.6 | Target DB: grp_parkitdb
#>

[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

Write-Host "================================================================" -ForegroundColor Blue
Write-Host "  PARK-IT DATABASE MANAGEMENT SYSTEM — AUTOMATED BACKUP UTILITY " -ForegroundColor Cyan
Write-Host "  COMP 018 Database Administration (Activity 6: Part B - Windows)" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Blue

# --- Check PostgreSQL client tools ---
$pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
if (-not $pgDumpCmd) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin"
    if (Test-Path $standardPath) {
        $env:PATH = "$env:PATH;$standardPath"
        $pgDumpCmd = Get-Command pg_dump.exe -ErrorAction SilentlyContinue
    }
}

if (-not $pgDumpCmd) {
    Write-Error "[ERROR] pg_dump.exe was not found in PATH or standard PostgreSQL directories."
    exit 1
}

$pgVersion = & pg_dump.exe --version
Write-Host "[OK] Detected backup tool: $pgVersion" -ForegroundColor Green

# --- Configuration Prompts ---
Write-Host "`n--- Database Connection Configuration ---" -ForegroundColor Yellow
$dbHost = Read-Host "Enter Database Host [localhost]"
if ([string]::IsNullOrWhiteSpace($dbHost)) { $dbHost = "localhost" }

$dbPort = Read-Host "Enter Database Port [5432]"
if ([string]::IsNullOrWhiteSpace($dbPort)) { $dbPort = "5432" }

$dbName = Read-Host "Enter Database Name [grp_parkitdb]"
if ([string]::IsNullOrWhiteSpace($dbName)) { $dbName = "grp_parkitdb" }

$dbUser = Read-Host "Enter Administrative Username [postgres]"
if ([string]::IsNullOrWhiteSpace($dbUser)) { $dbUser = "postgres" }

# --- Secure Password Handling ---
if (-not $env:PGPASSWORD) {
    Write-Host "Enter PostgreSQL password for user '$dbUser':" -ForegroundColor Yellow
    $securePass = Read-Host -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePass)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

# --- Paths and Output Directory ---
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$backupDir = Join-Path $scriptDir "..\backups"
if (-not (Test-Path $backupDir)) {
    New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFilename = "${dbName}_${timestamp}.dump"
$backupPath = Join-Path $backupDir $backupFilename
$canonicalPath = Join-Path $backupDir "${dbName}_activity6.dump"
$checksumPath = "${backupPath}.sha256"
$logFile = Join-Path $backupDir "backup_execution.log"

if (Test-Path $backupPath) {
    Write-Error "[ERROR] Backup file already exists: $backupPath. Aborting to prevent overwrite."
    exit 1
}

Write-Host "`n--- Commencing Logical Backup ---" -ForegroundColor Blue
Write-Host "Target Database : $dbName" -ForegroundColor Cyan
Write-Host "Host:Port       : ${dbHost}:${dbPort}" -ForegroundColor Cyan
Write-Host "Database User   : $dbUser" -ForegroundColor Cyan
Write-Host "Output Archive  : $backupPath" -ForegroundColor Cyan
Write-Host "Archive Format  : PostgreSQL Custom Format (-Fc, compressed)" -ForegroundColor Cyan

$startTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "Execution Start : $startTime"

# Execute pg_dump
$errLog = "${backupPath}.err.tmp"
& pg_dump.exe -h $dbHost -p $dbPort -U $dbUser -Fc -b -v -d $dbName -f $backupPath 2> $errLog
$dumpExit = $LASTEXITCODE
$endTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

if ($dumpExit -ne 0) {
    Write-Host "`n[ERROR] pg_dump failed with exit code $dumpExit." -ForegroundColor Red
    if (Test-Path $errLog) { Get-Content $errLog | Write-Host -ForegroundColor Red }
    "[$endTime] FAILED: Backup of $dbName failed with exit code $dumpExit" | Out-File -Append -FilePath $logFile
    if (Test-Path $backupPath) { Remove-Item $backupPath -Force }
    exit $dumpExit
}

if (Test-Path $errLog) { Remove-Item $errLog -Force }

# Verify file exists and is not empty
if (-not (Test-Path $backupPath) -or (Get-Item $backupPath).Length -eq 0) {
    Write-Host "`n[ERROR] Backup file was created but is empty (0 bytes)." -ForegroundColor Red
    exit 1
}

$fileSizeBytes = (Get-Item $backupPath).Length
$fileSizeHuman = "$([math]::Round($fileSizeBytes / 1KB, 2)) KB"

# SHA-256 Checksum
$shaHash = (Get-FileHash -Path $backupPath -Algorithm SHA256).Hash.ToLower()
"$shaHash  $backupFilename" | Out-File -FilePath $checksumPath -Encoding ascii

# Copy to canonical activity6 link
Copy-Item -Path $backupPath -Destination $canonicalPath -Force
"$shaHash  ${dbName}_activity6.dump" | Out-File -FilePath "${canonicalPath}.sha256" -Encoding ascii

# Log result
@"
[$endTime] SUCCESS: Backup completed successfully.
  Database       : $dbName
  Host:Port      : ${dbHost}:${dbPort}
  Filename       : $backupFilename
  File Size      : $fileSizeBytes bytes ($fileSizeHuman)
  SHA-256 Hash   : $shaHash
  Exit Code      : 0
  Start Time     : $startTime
  End Time       : $endTime
--------------------------------------------------------------------------------
"@ | Out-File -Append -FilePath $logFile

Write-Host "`n================================================================" -ForegroundColor Green
Write-Host "  BACKUP COMPLETED SUCCESSFULLY!                                " -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Database Name    : $dbName" -ForegroundColor Cyan
Write-Host "Backup File      : $backupPath" -ForegroundColor Cyan
Write-Host "Canonical File   : $canonicalPath" -ForegroundColor Cyan
Write-Host "File Size        : $fileSizeBytes bytes ($fileSizeHuman)" -ForegroundColor Cyan
Write-Host "SHA-256 Checksum : $shaHash" -ForegroundColor Cyan
Write-Host "Checksum File    : $checksumPath" -ForegroundColor Cyan
Write-Host "Execution Log    : $logFile" -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Green
Write-Host "Next Step: Run .\03-inspect-backup.ps1 or ./03-inspect-backup.sh`n" -ForegroundColor Yellow

