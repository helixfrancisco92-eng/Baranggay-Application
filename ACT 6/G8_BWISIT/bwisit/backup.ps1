<#
==============================================================================
COMP 018 - Database Administration | Activity 6
Script: backup.ps1
Target: Campus Canteen Pre-Order and Queue Management System (canteen_db)
Role: canteen_admin (or authorized PostgreSQL administrator)
Format: PostgreSQL Custom Archive (-Fc)
==============================================================================
#>
[CmdletBinding()]
param(
    [string]$HostName = "localhost",
    [int]$Port = 5432,
    [string]$Database = "canteen_db",
    [string]$User = "canteen_admin",
    [string]$BackupDir = "",
    [string]$PsqlPath = "C:\Program Files\PostgreSQL\18\bin"
)

$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$workspaceRoot = Split-Path -Parent $scriptDir
$logsDir = Join-Path $workspaceRoot "logs"
$defaultBackupDir = Join-Path $workspaceRoot "backups"

if (-not (Test-Path $logsDir)) { New-Item -ItemType Directory -Path $logsDir -Force | Out-Null }
if ([string]::IsNullOrWhiteSpace($BackupDir)) { $BackupDir = $defaultBackupDir }
if (-not (Test-Path $BackupDir)) { New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null }

Write-Host "==============================================================================" -ForegroundColor Cyan
Write-Host " COMP 018 Activity 6 - PostgreSQL Database Logical Backup (PowerShell)" -ForegroundColor Cyan
Write-Host " Project: Group 8 - Campus Canteen Pre-Order & Queue Management System" -ForegroundColor Cyan
Write-Host " Target Database: $Database" -ForegroundColor Cyan
Write-Host " Host: ${HostName}:${Port} | User: $User" -ForegroundColor Cyan
Write-Host "==============================================================================" -ForegroundColor Cyan

# Locate pg_dump executable
$pgDump = Get-Command "pg_dump" -ErrorAction SilentlyContinue
if (-not $pgDump) {
    $candidate = Join-Path $PsqlPath "pg_dump.exe"
    if (Test-Path $candidate) {
        $pgDumpPath = $candidate
    } else {
        throw "pg_dump.exe not found on PATH or at '$candidate'. Specify valid -PsqlPath."
    }
} else {
    $pgDumpPath = $pgDump.Source
}

# Acquire password securely
$securePw = $null
if (-not $env:PGPASSWORD) {
    $securePw = Read-Host "Enter password for database user '$User'" -AsSecureString
    $bstr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($securePw)
    $env:PGPASSWORD = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($bstr)
}

$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
$backupFilename = "${Database}_${timestamp}.dump"
$backupFilepath = Join-Path $BackupDir $backupFilename
$checksumFilepath = "${backupFilepath}.sha256"
$logFile = Join-Path $logsDir "backup-execution.log"

Write-Host "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] Running pg_dump (-Fc)..." -ForegroundColor Yellow
Write-Host "Destination: $backupFilepath"

try {
    & $pgDumpPath -h $HostName -p $Port -U $User -Fc -b -v -d $Database -f $backupFilepath 2>> $logFile
    if ($LASTEXITCODE -ne 0) {
        throw "pg_dump failed with exit code $LASTEXITCODE. See $logFile"
    }

    $item = Get-Item $backupFilepath
    if ($item.Length -le 0) {
        throw "Backup archive file was created with 0 bytes size."
    }

    $hash = (Get-FileHash -Path $backupFilepath -Algorithm SHA256).Hash.ToLower()
    Set-Content -Path $checksumFilepath -Value "$hash  $backupFilename"

    Write-Host "==============================================================================" -ForegroundColor Green
    Write-Host " BACKUP METRICS AND RECORDING" -ForegroundColor Green
    Write-Host "==============================================================================" -ForegroundColor Green
    Write-Host " Database Name  : $Database"
    Write-Host " Backup File    : $backupFilename"
    Write-Host " Full Path      : $backupFilepath"
    Write-Host " File Size      : $($item.Length) bytes ($([math]::Round($item.Length / 1KB, 2)) KB)"
    Write-Host " SHA-256 Hash   : $hash"
    Write-Host " Completed At   : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
    Write-Host " Checksum File  : $checksumFilepath"
    Write-Host " Execution Log  : $logFile"
    Write-Host "==============================================================================" -ForegroundColor Green

    $logEntry = @"
--------------------------------------------------------------------------------
Backup Executed : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Target Database : $Database
Host / Port     : ${HostName}:${Port}
User            : $User
Backup Archive  : $backupFilename
File Size       : $($item.Length) bytes
SHA-256 Hash    : $hash
Result          : SUCCESS (Exit Code 0)
--------------------------------------------------------------------------------
"@
    Add-Content -Path $logFile -Value $logEntry
    Write-Host "Next step: Run 'inspect-backup.ps1' to verify archive table-of-contents (TOC)." -ForegroundColor Cyan
}
catch {
    Write-Error "Backup operation failed: $_"
    if (Test-Path $backupFilepath) { Remove-Item $backupFilepath -Force -ErrorAction SilentlyContinue }
    exit 1
}
finally {
    Remove-Item Env:PGPASSWORD -ErrorAction SilentlyContinue
}

