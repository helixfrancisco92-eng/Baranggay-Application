@echo off
cd /d "%~dp0"
title iBarangay - Server Runner

echo =========================================================
echo               Starting iBarangay Server
echo =========================================================
echo.

:: 1. Read config from .env or application.properties
set "SERVER_PORT=8084"
if exist ".env" (
    for /f "usebackq tokens=1,* delims==" %%A in (".env") do (
        if "%%A"=="PORT" set "SERVER_PORT=%%B"
        if "%%A"=="DB_PASSWORD" set "DB_PASSWORD=%%B"
        if "%%A"=="DB_USER" set "DB_USER=%%B"
        if "%%A"=="DB_NAME" set "DB_NAME=%%B"
        if "%%A"=="DB_PORT" set "DB_PORT=%%B"
    )
)

:: 2. Check and free port if held by a lingering process
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

:: 3. Auto-detect PostgreSQL
where psql >nul 2>nul
if %ERRORLEVEL% neq 0 (
    if exist "D:\Postgre\pg_env.bat" call "D:\Postgre\pg_env.bat" >nul 2>nul
    if exist "D:\Postgre\bin\psql.exe" set "PATH=D:\Postgre\bin;%PATH%"
)

:: 4. Auto-detect Java
where java >nul 2>nul
if %ERRORLEVEL% neq 0 (
    if exist "C:\Program Files\Common Files\Oracle\Java\javapath\java.exe" (
        set "PATH=C:\Program Files\Common Files\Oracle\Java\javapath;%PATH%"
    )
)

echo.
echo Launching Spring Boot on http://localhost:%SERVER_PORT%/
echo Press Ctrl+C in this terminal to stop the server.
echo.

call "%~dp0mvnw.cmd" spring-boot:run
if %ERRORLEVEL% neq 0 (
    echo.
    echo =========================================================
    echo [ERROR] Application stopped or failed to start.
    echo =========================================================
    pause
    exit /b 1
)

pause
