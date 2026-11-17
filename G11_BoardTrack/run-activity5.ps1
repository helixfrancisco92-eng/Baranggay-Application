<#
.SYNOPSIS
    Activity 5 Database Maintenance and Monitoring Execution Helper
    Target Project: BoardTrack – Boarding House & Rental Management System
.DESCRIPTION
    Runs the Activity 5 diagnostic and maintenance SQL scripts against the configured
    PostgreSQL database, capturing clean transcripts into the evidence/ directory.
.PARAMETER Step
    The maintenance or monitoring step to execute:
    - health      : Runs 01_database_health_check.sql
    - activity    : Runs 02_activity_monitoring.sql
    - stats       : Runs 03_table_statistics.sql
    - index       : Runs 04_index_monitoring.sql
    - query       : Runs 05_query_performance.sql
    - maintain    : Runs 06_maintenance_operations.sql
    - all         : Runs all diagnostic scripts in sequence
.PARAMETER Database
    The PostgreSQL target database (default: boardtrack_db).
.PARAMETER User
    The PostgreSQL user to connect as (default: postgres or boardtrack_owner).
.PARAMETER Host
    Database host (default: localhost).
.PARAMETER Port
    Database port (default: 5432).
.EXAMPLE
    .\run-activity5.ps1 -Step health -User postgres -Database boardtrack_db
    .\run-activity5.ps1 -Step maintain -User postgres -Database boardtrack_db
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [ValidateSet("health", "activity", "stats", "index", "query", "maintain", "all")]
    [string]$Step = "health",

    [Parameter(Mandatory=$false)]
    [string]$Database = "boardtrack_db",

    [Parameter(Mandatory=$false)]
    [string]$User = "postgres",

    [Parameter(Mandatory=$false)]
    [string]$HostName = "localhost",

    [Parameter(Mandatory=$false)]
    [int]$Port = 5432
)

$ErrorActionPreference = "Stop"

# 1. Locate psql binary
$psqlPath = "psql"
if (-not (Get-Command "psql" -ErrorAction SilentlyContinue)) {
    $standardPath = "C:\Program Files\PostgreSQL\18\bin\psql.exe"
    if (Test-Path $standardPath) {
        $psqlPath = $standardPath
    } else {
        throw "psql executable was not found on PATH or in C:\Program Files\PostgreSQL\18\bin."
    }
}

# 2. Directory and Evidence Setup
$baseDir = $PSScriptRoot
$sqlDir = Join-Path $baseDir "sql"
$evidenceDir = Join-Path $baseDir "evidence"
if (-not (Test-Path $evidenceDir)) {
    New-Item -ItemType Directory -Path $evidenceDir -Force | Out-Null
}

$scriptMap = @{
    "health"   = @("01_database_health_check.sql", "A5-01_database_health_check.txt")
    "activity" = @("02_activity_monitoring.sql", "A5-02_activity_monitoring.txt")
    "stats"    = @("03_table_statistics.sql", "A5-03_table_statistics.txt")
    "index"    = @("04_index_monitoring.sql", "A5-04_index_monitoring.txt")
    "query"    = @("05_query_performance.sql", "A5-05_query_performance.txt")
    "maintain" = @("06_maintenance_operations.sql", "A5-06_maintenance_operations.txt")
}

function Execute-SqlStep([string]$stepKey) {
    $sqlFile = Join-Path $sqlDir $scriptMap[$stepKey][0]
    $logFile = Join-Path $evidenceDir $scriptMap[$stepKey][1]

    if (-not (Test-Path $sqlFile)) {
        throw "SQL script not found: $sqlFile"
    }

    Write-Host "`n========================================================" -ForegroundColor Cyan
    Write-Host " Executing Step: $stepKey" -ForegroundColor Cyan
    Write-Host " Script: $sqlFile" -ForegroundColor Cyan
    Write-Host " Target: ${User}@${HostName}:${Port}/${Database}" -ForegroundColor Cyan
    Write-Host " Log:    $logFile" -ForegroundColor Cyan
    Write-Host "========================================================`n" -ForegroundColor Cyan

    & $psqlPath -h $HostName -p $Port -U $User -d $Database -f $sqlFile 2>&1 | Tee-Object -FilePath $logFile
    Write-Host "Saved transcript to: $logFile" -ForegroundColor Green
}

if ($Step -eq "all") {
    foreach ($k in @("health", "activity", "stats", "index", "query")) {
        Execute-SqlStep $k
    }
    Write-Host "`nDiagnostic suite completed. To execute maintenance, run with -Step maintain.`n" -ForegroundColor Yellow
} else {
    Execute-SqlStep $Step
}
