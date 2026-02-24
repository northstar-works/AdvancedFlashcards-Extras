@echo off
setlocal enabledelayedexpansion

set "TOOL_VER=1.2.0"
set "TOOL_BUILD=9"

REM ── Log to same folder as bat ──────────────────────────────
set "LOG=%~dp0synctool.log"
echo SyncTool Log - %DATE% %TIME% > "%LOG%"
echo ================================================== >> "%LOG%"
echo. >> "%LOG%"
echo [START] Tool version %TOOL_VER% build %TOOL_BUILD% >> "%LOG%"

REM ── Paths ──────────────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
echo [PATH] SCRIPT_DIR: %SCRIPT_DIR% >> "%LOG%"

set "MONO_ROOT=%SCRIPT_DIR%\..\.."
pushd "%MONO_ROOT%" >nul 2>&1
set "MONO_ROOT=%CD%"
popd >nul
echo [PATH] MONO_ROOT: %MONO_ROOT% >> "%LOG%"

set "WS_DIR=%MONO_ROOT%\KenpoFlashcardsWebServer"
set "CONFIG_FILE=%SCRIPT_DIR%\rpi_config.txt"
echo [PATH] CONFIG_FILE: %CONFIG_FILE% >> "%LOG%"

REM ── Defaults ───────────────────────────────────────────────
set "RPI_IP="
set "RPI_USER="
set "RPI_PASS="
set "RPI_PORT=22"
set "RPI_INSTALL=/opt/advanced-flashcards"
set "RPI_SERVICE=advanced-flashcards"
set "MODE=code"

REM ── Load config ────────────────────────────────────────────
if exist "%CONFIG_FILE%" (
    echo [CONFIG] Loading from %CONFIG_FILE% >> "%LOG%"
    for /f "usebackq tokens=1,* delims==" %%K in ("%CONFIG_FILE%") do (
        if /i "%%K"=="ip"   set "RPI_IP=%%L"
        if /i "%%K"=="user" set "RPI_USER=%%L"
        if /i "%%K"=="port" set "RPI_PORT=%%L"
        if /i "%%K"=="pass" set "RPI_PASS=%%L"
    )
    echo [CONFIG] Loaded - IP=%RPI_IP% USER=%RPI_USER% >> "%LOG%"
) else (
    echo [CONFIG] No config file found >> "%LOG%"
)

REM ── Parse args ─────────────────────────────────────────────
:parse
if "%~1"=="" goto done_parse
echo [ARG] Processing: %~1 >> "%LOG%"
if /i "%~1"=="--code"    set "MODE=code" & shift & goto parse
if /i "%~1"=="--status"  set "MODE=status" & shift & goto parse
if /i "%~1"=="--restart" set "MODE=restart" & shift & goto parse
if /i "%~1"=="--help"    goto help
if /i "%~1"=="-h"        goto help
shift & goto parse
:done_parse

echo [MODE] Selected mode: %MODE% >> "%LOG%"

REM ── Prompt ─────────────────────────────────────────────────
cls
echo.
echo  ====================================================
echo   SyncTool: WebServer to RPi  ^(v%TOOL_VER% b%TOOL_BUILD%^)
echo  ====================================================
echo.
echo  Log: %LOG%
echo.

if "%RPI_IP%"=="" (
    echo [PROMPT] Asking for IP >> "%LOG%"
    set /p RPI_IP="  RPi IP: "
    echo [INPUT] IP entered: !RPI_IP! >> "%LOG%"
)

if "%RPI_USER%"=="" (
    echo [PROMPT] Asking for username >> "%LOG%"
    set /p RPI_USER="  Username: "
    echo [INPUT] Username entered: !RPI_USER! >> "%LOG%"
)

if "%RPI_PASS%"=="" (
    echo [PROMPT] Asking for password >> "%LOG%"
    set /p RPI_PASS="  Password (or Enter): "
    if "!RPI_PASS!"=="" (
        echo [INPUT] Password: BLANK >> "%LOG%"
    ) else (
        echo [INPUT] Password: PROVIDED >> "%LOG%"
    )
)

echo [SAVE] About to save config >> "%LOG%"

REM ── Save config ────────────────────────────────────────────
if not exist "%CONFIG_FILE%" (
    echo [SAVE] Writing config file >> "%LOG%"
    (
        echo ip=%RPI_IP%
        echo user=%RPI_USER%
        echo port=%RPI_PORT%
        echo pass=%RPI_PASS%
    ) > "%CONFIG_FILE%" 2>> "%LOG%"
    
    if exist "%CONFIG_FILE%" (
        echo [SAVE] SUCCESS - Config created >> "%LOG%"
        echo.
        echo  Config saved to: %CONFIG_FILE%
    ) else (
        echo [SAVE] FAILED - Config not created >> "%LOG%"
    )
)

REM ── Normalize IP ───────────────────────────────────────────
echo [NORMALIZE] Original IP: %RPI_IP% >> "%LOG%"
set "RPI_HOST=%RPI_IP%"
set "RPI_HOST=%RPI_HOST:http://=%"
set "RPI_HOST=%RPI_HOST:https://=%"
for /f "tokens=1 delims=/" %%a in ("%RPI_HOST%") do set "RPI_HOST=%%a"
for /f "tokens=1 delims=:" %%a in ("%RPI_HOST%") do set "RPI_HOST=%%a"
set "RPI_IP=%RPI_HOST%"
echo [NORMALIZE] Final IP: %RPI_IP% >> "%LOG%"

REM ── Setup SSH ──────────────────────────────────────────────
echo [SSH] Setting up SSH command >> "%LOG%"
set "SSHPASS_CMD="
if not "%RPI_PASS%"==" " (
    where sshpass >nul 2>&1
    if !errorlevel!==0 (
        set "SSHPASS_CMD=sshpass -p "%RPI_PASS%""
        echo [SSH] Using sshpass >> "%LOG%"
    ) else (
        echo [SSH] sshpass not found - will prompt for password >> "%LOG%"
    )
)

REM ── Dispatch ───────────────────────────────────────────────
echo [DISPATCH] Executing mode: %MODE% >> "%LOG%"

if "%MODE%"=="status"  goto status
if "%MODE%"=="restart" goto restart
if "%MODE%"=="code"    goto code

:status
echo [STATUS] Checking RPi status >> "%LOG%"
echo.
echo  Checking RPi status...
echo.
echo [CMD] ssh -p %RPI_PORT% "%RPI_USER%@%RPI_IP%" >> "%LOG%"
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_IP%" "systemctl status %RPI_SERVICE% --no-pager; cat %RPI_INSTALL%/app/version.json 2>/dev/null" >> "%LOG%" 2>&1
echo [STATUS] Command completed with errorlevel: %errorlevel% >> "%LOG%"
goto end

:restart
echo [RESTART] Restarting RPi service >> "%LOG%"
echo.
echo  Restarting RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_IP%" "sudo systemctl restart %RPI_SERVICE%" >> "%LOG%" 2>&1
echo [RESTART] Command completed with errorlevel: %errorlevel% >> "%LOG%"
goto end

:code
echo [SYNC] Starting code sync >> "%LOG%"
echo.
echo  Pushing code to RPi...
echo.
echo  [1/3] Stopping service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_IP%" "sudo systemctl stop %RPI_SERVICE%" >> "%LOG%" 2>&1

echo  [2/3] Uploading...
set "STAGE=%TEMP%\_sync_%RANDOM%"
robocopy "%WS_DIR%" "%STAGE%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS /XD data logs .venv __pycache__ .git /XF *.bat *.pyc >nul
%SSHPASS_CMD% scp -P %RPI_PORT% -r "%STAGE%\." "%RPI_USER%@%RPI_IP%:%RPI_INSTALL%/app/" >> "%LOG%" 2>&1
rmdir /s /q "%STAGE%"

echo  [3/3] Starting service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_IP%" "sudo systemctl start %RPI_SERVICE%" >> "%LOG%" 2>&1
echo.
echo  Done!
goto end

:help
echo.
echo  Usage: SyncTool-WebServerToRPi.bat [options]
echo.
echo  --code     Push code (default)
echo  --status   Show status
echo  --restart  Restart service
echo.
pause
exit /b 0

:end
echo.
echo [END] Tool completed >> "%LOG%"
echo Log saved to: %LOG%
echo.
timeout /t 30
notepad "%LOG%"
exit /b 0
