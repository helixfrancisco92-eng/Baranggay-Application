@echo off
cd /d "%~dp0"
title iBarangay - Setup and Start

echo =========================================================
echo               iBarangay Application Setup
echo =========================================================
echo.

:: -----------------------------------------------------------
:: 1. Read Database & Server Config from .env or defaults
:: -----------------------------------------------------------
set "DB_USER=postgres"
set "DB_PASS=acads23"
set "DB_NAME=PPGG_projectdb"
set "DB_PORT=5432"
set "SERVER_PORT=8084"

if exist ".env" (
    for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
        if "%%A"=="PORT" set "SERVER_PORT=%%B"
        if "%%A"=="DB_PASSWORD" set "DB_PASS=%%B"
        if "%%A"=="DB_USER" set "DB_USER=%%B"
        if "%%A"=="DB_NAME" set "DB_NAME=%%B"
        if "%%A"=="DB_PORT" set "DB_PORT=%%B"
    )
)

:: -----------------------------------------------------------
:: 2. Free up Port if occupied (Zombie Process Cleanup)
:: -----------------------------------------------------------
echo Checking port %SERVER_PORT%...
set "FOUND_PID="
for /f "tokens=5" %%P in ('netstat -a -n -o ^| findstr :%SERVER_PORT% ^| findstr LISTENING') do (
    set "FOUND_PID=%%P"
)
if defined FOUND_PID (
    echo Freeing port %SERVER_PORT% held by process %FOUND_PID%
    taskkill /F /PID %FOUND_PID% >nul 2>nul
    timeout /t 1 /nobreak >nul
) else (
    echo Port %SERVER_PORT% is available.
)

:: -----------------------------------------------------------
:: 3. Check & Configure Java
:: -----------------------------------------------------------
echo [1/3] Checking Java installation...
where java >nul 2>nul
if %ERRORLEVEL% neq 0 (
    if exist "C:\Program Files\Common Files\Oracle\Java\javapath\java.exe" (
        set "PATH=C:\Program Files\Common Files\Oracle\Java\javapath;%PATH%"
    )
)

where java >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo [ERROR] Java is not detected in your PATH!
    echo Please install JDK 21 and ensure JAVA_HOME is set.
    goto :error
)
java -version
echo [OK] Java detected.
echo.

:: -----------------------------------------------------------
:: 4. Check & Configure PostgreSQL
:: -----------------------------------------------------------
echo [2/3] Checking PostgreSQL configuration...
echo Target Database : %DB_NAME%
echo Target User     : %DB_USER%
echo Target Port     : %DB_PORT%
echo.

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
    set "PATH=D:\Postgre\bin;%PATH%"
    set "PSQL_BIN=D:\Postgre\bin\psql.exe"
    echo [INFO] Detected PostgreSQL at D:\Postgre\bin
    goto :found_psql
)

for %%D in (C D E) do (
    for /d %%V in ("%%D:\Program Files\PostgreSQL\*") do (
        if exist "%%V\bin\psql.exe" (
            set "PATH=%%V\bin;%PATH%"
            set "PSQL_BIN=%%V\bin\psql.exe"
            echo [INFO] Detected PostgreSQL at %%V\bin
            goto :found_psql
        )
    )
)

:found_psql
if "%PSQL_BIN%"=="" (
    echo [WARNING] 'psql' was not found automatically in standard directories.
    echo The application will attempt to auto-create the database using Java JDBC on startup.
) else (
    echo [OK] PostgreSQL CLI found: %PSQL_BIN%
    set "PGPASSWORD=%DB_PASS%"
    echo Testing connection to PostgreSQL on port %DB_PORT%...
    "%PSQL_BIN%" -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -c "SELECT 1;" >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo [INFO] PostgreSQL service not responding. Attempting to start 'postgresql-x64-18'...
        net start postgresql-x64-18 >nul 2>nul
        timeout /t 2 >nul
    )
    "%PSQL_BIN%" -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -tc "SELECT 1 FROM pg_database WHERE datname = '%DB_NAME%'" 2>nul | findstr "1" >nul 2>nul
    if %ERRORLEVEL% neq 0 (
        echo Creating database '%DB_NAME%'...
        "%PSQL_BIN%" -U %DB_USER% -h localhost -p %DB_PORT% -d postgres -c "CREATE DATABASE \"%DB_NAME%\";" >nul 2>nul
        if %ERRORLEVEL% equ 0 (
            echo [OK] Database '%DB_NAME%' created successfully!
        ) else (
            echo [INFO] Will auto-create database via Spring Boot startup JDBC.
        )
    ) else (
        echo [OK] Database '%DB_NAME%' already exists.
    )
)

echo.
:: -----------------------------------------------------------
:: 5. Launch Application
:: -----------------------------------------------------------
echo [3/3] Launching iBarangay Application...
echo Access the portal at: http://localhost:%SERVER_PORT%/
echo.

call "%~dp0mvnw.cmd" spring-boot:run
if %ERRORLEVEL% neq 0 (
    goto :error
)

pause
exit /b 0

:error
echo.
echo =========================================================
echo [ERROR] Application failed to start.
echo Please review the error log above or consult docs/troubleshooting.md.
echo =========================================================
pause
exit /b 1
