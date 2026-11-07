@echo off
setlocal enabledelayedexpansion
title iBarangay - Database Initializer

echo =========================================================
echo              iBarangay Database Initializer
echo =========================================================
echo.

set "APP_PROPS=%~dp0src\main\resources\application.properties"
set "DB_USER=postgres"
set "DB_PASS=acads23"
set "DB_NAME=PPGG_projectdb"
set "DB_PORT=5432"

if exist "%APP_PROPS%" (
    for /f "tokens=1,* delims==" %%A in ('type "%APP_PROPS%"') do (
        set "KEY=%%A"
        set "VAL=%%B"
        for /f "tokens=* delims= " %%K in ("!KEY!") do set "KEY=%%K"
        for /f "tokens=* delims= " %%V in ("!VAL!") do set "VAL=%%V"
        if "!KEY!"=="spring.datasource.username" set "DB_USER=!VAL!"
        if "!KEY!"=="spring.datasource.password" set "DB_PASS=!VAL!"
    )
)

echo Target Database  : %DB_NAME%
echo Username         : %DB_USER%
echo Port             : %DB_PORT%
echo.

:: 1. Detect PostgreSQL / psql
set "PSQL_BIN="

where psql >nul 2>nul
if %ERRORLEVEL% equ 0 (
    set "PSQL_BIN=psql"
    goto :found_psql
)

if exist "D:\Postgre\pg_env.bat" (
    call "D:\Postgre\pg_env.bat"
    set "PSQL_BIN=psql"
    echo [INFO] Detected PostgreSQL at D:\Postgre
    goto :found_psql
)
if exist "D:\Postgre\bin\psql.exe" (
    set "PATH=D:\Postgre\bin;!PATH!"
    set "PSQL_BIN=D:\Postgre\bin\psql.exe"
    echo [INFO] Detected PostgreSQL at D:\Postgre\bin
    goto :found_psql
)

for %%D in (C D E) do (
    for /d %%V in ("%%D:\Program Files\PostgreSQL\*") do (
        if exist "%%V\bin\psql.exe" (
            set "PATH=%%V\bin;!PATH!"
            set "PSQL_BIN=%%V\bin\psql.exe"
            echo [INFO] Detected PostgreSQL at %%V\bin
            goto :found_psql
        )
    )
)

:found_psql
if "!PSQL_BIN!"=="" (
    echo [ERROR] 'psql' command not found in your PATH or at D:\Postgre\bin.
    echo Please add D:\Postgre\bin to your System PATH, or create 'PPGG_projectdb' in pgAdmin.
    pause
    exit /b 1
)

set PGPASSWORD=%DB_PASS%

:: 2. Test connection and start service if needed
echo Testing connection to PostgreSQL on localhost:%DB_PORT%...
psql -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -c "SELECT 1;" >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo [INFO] PostgreSQL service not responding. Attempting to start 'postgresql-x64-18'...
    net start postgresql-x64-18 >nul 2>nul
    timeout /t 2 >nul
    psql -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -c "SELECT 1;" >nul 2>nul
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] Authentication failed or service unavailable!
        echo If your password is NOT '%DB_PASS%', please update 'spring.datasource.password' in:
        echo   src\main\resources\application.properties
        pause
        exit /b 1
    )
    echo [OK] PostgreSQL service started successfully!
)

:: 3. Create database
echo Checking if '%DB_NAME%' exists...
psql -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '%DB_NAME%'" 2>nul | findstr "1" >nul 2>nul
if !ERRORLEVEL! neq 0 (
    echo Database '%DB_NAME%' does not exist. Creating...
    psql -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -c "CREATE DATABASE \"%DB_NAME%\";"
    if !ERRORLEVEL! equ 0 (
        echo [OK] Database '%DB_NAME%' created successfully!
    ) else (
        echo [ERROR] Failed to create database. Please check credentials or create in pgAdmin.
    )
) else (
    echo [OK] Database '%DB_NAME%' already exists!
)

echo.
echo Done.
pause
