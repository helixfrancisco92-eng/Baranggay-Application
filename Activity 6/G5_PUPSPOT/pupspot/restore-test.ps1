<#
==============================================================================
PUP-SPOT (Group 5) — Automated Database Restoration Test Script (PowerShell)
Course: COMP 018 — Database Administration (Activity 6: Part C)
Target Project: PUP-SPOT Lost and Found System
Source Database: grp05_lostandfounddb
Disposable Test Database: grp05_lostandfounddb_activity6_restore_test
==============================================================================
#>

[CmdletBinding()]
param (
    [string]$HostName = "localhost",
    [string]$Port = "5432",
    [string]$SourceDatabase = "grp05_lostandfounddb",
    [string]$TestDatabase = "grp05_lostandfounddb_activity6_restore_test",
    [string]$Username = "lf_admin_user",
    [string]$AdminUsername = "postgres",
    [string]$BackupFile = "C:\Users\Lenovo\Downloads\backups\grp05_lostandfounddb_backup_20261112_235620.dump"
)

$ErrorActionPreference = "Stop"

if (-not $env:PGPASSWORD) {
    $env:PGPASSWORD = "AdminPassword123"
}
$env:PGCONNECT_TIMEOUT = "3"

Write-Host "=================================================================" -ForegroundColor Cyan
Write-Host " PUP-SPOT Isolated Database Restoration Test                     " -ForegroundColor Cyan
Write-Host " Course: COMP 018 Database Administration (Activity 6)           " -ForegroundColor Cyan
Write-Host "=================================================================" -ForegroundColor Cyan

# 1. Safety Safeguards: Confirm Database Separation
Write-Host "`n[1/6] Safety Validation Checks..." -ForegroundColor Yellow
if ($SourceDatabase -eq $TestDatabase) {
    Write-Error "[ABORT] Source database and test database cannot have the same name ($SourceDatabase). Overwrite prevented."
    exit 1
}
Write-Host "      [SAFE] Source Database : $SourceDatabase" -ForegroundColor Green
Write-Host "      [SAFE] Test Database   : $TestDatabase" -ForegroundColor Green

# 2. Confirm Backup Archive Existence
Write-Host "`n[2/6] Verifying Backup Archive..." -ForegroundColor Yellow
if (-not (Test-Path $BackupFile)) {
    $latestDump = Get-ChildItem "C:\Users\Lenovo\Downloads\backups\*.dump" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latestDump) {
        $BackupFile = $latestDump.FullName
    } else {
        Write-Error "[FATAL] Backup file does not exist: $BackupFile"
        exit 1
    }
}
$fileItem = Get-Item $BackupFile
$sha256 = (Get-FileHash -Path $BackupFile -Algorithm SHA256).Hash
Write-Host "      Archive File   : $($fileItem.FullName)" -ForegroundColor Green
Write-Host "      Archive Size   : $($fileItem.Length) bytes" -ForegroundColor Green
Write-Host "      SHA-256 Hash   : $sha256" -ForegroundColor Green

# 3. Inspect Table of Contents before Restoring
Write-Host "`n[3/6] Inspecting Archive TOC (pg_restore --list)..." -ForegroundColor Yellow
$tocCheck = & pg_restore --list $BackupFile 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "[FATAL] Archive inspection failed. Cannot proceed with restoration."
    exit 1
}
Write-Host "      Archive TOC verified. Exit code: 0." -ForegroundColor Green

# 4. Provision Isolated Test Database
Write-Host "`n[4/6] Provisioning Isolated Test Database ($TestDatabase)..." -ForegroundColor Yellow
Write-Host "      Executing: createdb -U $Username -h $HostName -p $Port $TestDatabase" -ForegroundColor Gray

# Attempt createdb with primary account
$createDbResult = ""
$createExitCode = 0
try {
    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
    $pinfo.FileName = "createdb.exe"
    $pinfo.Arguments = "-U $Username -h $HostName -p $Port $TestDatabase"
    $pinfo.RedirectStandardError = $true
    $pinfo.RedirectStandardOutput = $true
    $pinfo.UseShellExecute = $false
    $p = [System.Diagnostics.Process]::Start($pinfo)
    $p.WaitForExit()
    $createExitCode = $p.ExitCode
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    $createDbResult = "$stdout $stderr".Trim()
} catch {
    $createExitCode = 1
    $createDbResult = $_.Exception.Message
}

if ($createExitCode -ne 0) {
    Write-Warning "      [NOTICE] createdb with user '$Username' returned exit code $createExitCode."
    Write-Warning "      Output: $createDbResult"
    
    if ($createDbResult -like "*permission denied to create database*") {
        Write-Warning "      [PERMISSION LIMITATION] Role '$Username' lacks cluster-level CREATEDB privilege."
        Write-Warning "      Database creation in PostgreSQL requires the cluster administrator ('$AdminUsername')."
        Write-Host "      Attempting database creation with '$AdminUsername' if PGPASSWORD_ADMIN is provided..." -ForegroundColor Gray
        
        if ($env:PGPASSWORD_ADMIN) {
            $env:PGPASSWORD = $env:PGPASSWORD_ADMIN
            $createDbResult = & createdb -U $AdminUsername -h $HostName -p $Port $TestDatabase 2>&1
            $createExitCode = $LASTEXITCODE
        }
    }
}

if ($createExitCode -eq 0 -or $createDbResult -like "*already exists*") {
    Write-Host "      Target test database ready for restoration." -ForegroundColor Green
    $dbReady = $true
} else {
    Write-Host "      [STATUS: BLOCKED / PENDING] Isolated test database could not be auto-created without superuser credentials." -ForegroundColor Red
    Write-Host "      Instruction: An administrator must execute: createdb -U $AdminUsername -h $HostName -p $Port $TestDatabase" -ForegroundColor Yellow
    $dbReady = $false
}

# 5. Execute pg_restore if database is ready
Write-Host "`n[5/6] Executing Database Restoration (pg_restore)..." -ForegroundColor Yellow
if ($dbReady) {
    Write-Host "      Restoring archive into $TestDatabase..." -ForegroundColor Gray
    $restoreStart = Get-Date
    $restoreOutput = & pg_restore -U $Username -h $HostName -p $Port -d $TestDatabase --verbose $BackupFile 2>&1
    $restoreExitCode = $LASTEXITCODE
    $restoreDuration = ((Get-Date) - $restoreStart).TotalSeconds
    
    Write-Host "      Restoration Output:"
    Write-Host ($restoreOutput | Out-String)
    Write-Host "      Exit Code: $restoreExitCode (Duration: $([math]::Round($restoreDuration, 2))s)"
    
    if ($restoreExitCode -eq 0) {
        Write-Host "      [SUCCESS] Restoration completed successfully without fatal errors." -ForegroundColor Green
    } else {
        Write-Warning "      [WARNING] pg_restore exited with code $restoreExitCode. Review warnings/errors above."
    }
} else {
    Write-Host "      [SKIPPED] Restoration skipped due to pending test database provisioning." -ForegroundColor Yellow
    $restoreExitCode = -1
}

# 6. Summary and Evidence Logging
Write-Host "`n[6/6] Summary of Restoration Test:" -ForegroundColor Yellow
Write-Host "================================================================="
Write-Host " Test Database   : $TestDatabase"
Write-Host " Target Archive  : $($fileItem.Name)"
Write-Host " Execution State : $(if ($dbReady) { 'EXECUTED (Code ' + $restoreExitCode + ')' } else { 'BLOCKED - Requires CREATEDB permission' })"
Write-Host " Timestamp       : $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
Write-Host "================================================================="
