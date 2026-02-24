@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM SyncTool-WebServerToRPi.bat
REM Push WebServer code and/or data from Windows dev to RPi.
REM
REM Place in: sidscri-apps\tools\SyncTool-WebServerToRPi\
REM Expects:  sidscri-apps\KenpoFlashcardsWebServer\ to exist
REM
REM Usage:
REM   SyncTool-WebServerToRPi.bat [rpi-ip] [options]
REM   (Double-click with no args: prompts interactively)
REM
REM Saved config (rpi_config.txt):
REM   ip=192.168.0.205
REM   user=sidscri
REM   port=22
REM   pass=              (optional - SSH will prompt if blank)
REM
REM Options:
REM   --code       Push code only (default)
REM   --data       Push data only
REM   --all        Push code + data
REM   --status     Show RPi service status (no push)
REM   --restart    Just restart RPi service
REM   --version    Show versions (local + RPi)
REM   --dry-run    Show what would be synced (no push)
REM   --save       Save all connection settings to rpi_config.txt
REM   --user <u>   RPi SSH user (overrides config)
REM   --port <p>   RPi SSH port (overrides config)
REM ============================================================

set "TOOL_VER=1.2.0"
set "TOOL_BUILD=4"

REM ── Resolve paths ──────────────────────────────────────────
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

set "MONO_ROOT=%SCRIPT_DIR%\..\.."
pushd "%MONO_ROOT%" >nul
set "MONO_ROOT=%CD%"
popd >nul

set "WS_DIR=%MONO_ROOT%\KenpoFlashcardsWebServer"
set "CONFIG_FILE=%SCRIPT_DIR%\rpi_config.txt"

REM ── Defaults ───────────────────────────────────────────────
set "RPI_IP="
set "RPI_HOST="
set "RPI_USER="
set "RPI_PASS="
set "RPI_PORT=22"
set "RPI_INSTALL=/opt/advanced-flashcards"
set "RPI_SERVICE=advanced-flashcards"
set "RPI_WEB_PORT=8009"

REM Mode flags
set "MODE=code"
set "DRY_RUN=0"
set "SAVE_CONFIG=0"

REM ── Load saved config ──────────────────────────────────────
if exist "%CONFIG_FILE%" (
    for /f "usebackq tokens=1,* delims==" %%K in ("%CONFIG_FILE%") do (
        if /i "%%K"=="ip"   set "RPI_IP=%%L"
        if /i "%%K"=="user" set "RPI_USER=%%L"
        if /i "%%K"=="port" set "RPI_PORT=%%L"
        if /i "%%K"=="pass" set "RPI_PASS=%%L"
    )
)

REM ── Parse arguments ────────────────────────────────────────
:parse_args
if "%~1"=="" goto :args_done

REM First positional arg that doesn't start with - is the IP
if "%RPI_IP%"=="" (
    echo %~1 | findstr /r "^-" >nul 2>&1
    if !errorlevel!==1 (
        set "RPI_IP=%~1"
        shift & goto :parse_args
    )
)

if /i "%~1"=="--code"    ( set "MODE=code"    & shift & goto :parse_args )
if /i "%~1"=="--data"    ( set "MODE=data"    & shift & goto :parse_args )
if /i "%~1"=="--all"     ( set "MODE=all"     & shift & goto :parse_args )
if /i "%~1"=="--status"  ( set "MODE=status"  & shift & goto :parse_args )
if /i "%~1"=="--restart" ( set "MODE=restart" & shift & goto :parse_args )
if /i "%~1"=="--version" ( set "MODE=version" & shift & goto :parse_args )
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1"   & shift & goto :parse_args )
if /i "%~1"=="--save"    ( set "SAVE_CONFIG=1" & shift & goto :parse_args )
if /i "%~1"=="--save-ip" ( set "SAVE_CONFIG=1" & shift & goto :parse_args )
if /i "%~1"=="--user"    ( set "RPI_USER=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--port"    ( set "RPI_PORT=%~2" & shift & shift & goto :parse_args )
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h"     goto :show_help

echo  [WARN] Unknown option ignored: %~1
shift & goto :parse_args

:args_done

REM ── Prompt for missing connection details ──────────────────
set "PROMPTED=0"

REM Show header if we need to prompt for anything
if "%RPI_IP%"=="" set "PROMPTED=1"
if "%RPI_USER%"=="" set "PROMPTED=1"

if "%PROMPTED%"=="1" (
    echo.
    echo  ====================================================
    echo   SyncTool: WebServer to RPi  ^(v%TOOL_VER% build %TOOL_BUILD%^)
    echo  ====================================================
    echo.
    echo   Enter your Raspberry Pi connection details.
    echo   These will be saved to rpi_config.txt for future runs.
    echo   ^(Delete rpi_config.txt to reset saved settings^)
    echo.
)

if "%RPI_IP%"=="" (
    set /p RPI_IP="  RPi IP or hostname: "
    if "!RPI_IP!"=="" (
        echo  [ERROR] No IP entered. Exiting.
        pause & exit /b 1
    )
    echo.
)

if "%RPI_USER%"=="" (
    set /p RPI_USER="  SSH username [default: pi]: "
    if "!RPI_USER!"=="" set "RPI_USER=pi"
    echo.
)

if "%PROMPTED%"=="1" (
    if "%RPI_PASS%"=="" (
        echo   SSH password (optional - press Enter to skip):
        echo   Tip: Leave blank if you use SSH key auth.
        echo   If saved, password is stored as plain text in rpi_config.txt.
        echo.
        set /p RPI_PASS="  SSH password (or Enter to skip): "
        echo.
    )
    set "SAVE_CONFIG=1"
)

REM ── Normalize host (strip http://, port, path) ─────────────
set "RPI_HOST=%RPI_IP%"
REM Strip http:// or https://
if "!RPI_HOST:~0,7!"=="http://" set "RPI_HOST=!RPI_HOST:~7!"
if "!RPI_HOST:~0,8!"=="https://" set "RPI_HOST=!RPI_HOST:~8!"
REM Strip trailing path
for /f "tokens=1 delims=/" %%a in ("!RPI_HOST!") do set "RPI_HOST=%%a"
REM Detect if port is embedded (host:port) and extract just the host
for /f "tokens=1 delims=:" %%a in ("!RPI_HOST!") do set "RPI_HOST=%%a"
set "RPI_IP=%RPI_HOST%"

set "RPI_WEB_URL=http://%RPI_HOST%:%RPI_WEB_PORT%"

REM ── Save config if prompted or --save flag used ────────────
if "%SAVE_CONFIG%"=="1" (
    (
        echo ip=%RPI_HOST%
        echo user=%RPI_USER%
        echo port=%RPI_PORT%
        echo pass=%RPI_PASS%
    ) > "%CONFIG_FILE%"
    echo  [CONFIG] Saved to %CONFIG_FILE%
    if "%RPI_PASS%"=="" (
        echo           pass= is blank - SSH will prompt for password each time.
        echo           Tip: set up SSH key auth to avoid password prompts.
    ) else (
        echo           WARNING: Password saved as plain text.
    )
    echo.
)

REM ── Build SSH/SCP password option ──────────────────────────
REM Native Windows ssh/scp don't support inline passwords.
REM If a password is saved, we check for sshpass (available via Git Bash/WSL).
REM Otherwise SSH will prompt interactively - that's fine.
set "SSH_EXTRA="
set "SSHPASS_CMD="
if not "%RPI_PASS%"=="" (
    where sshpass >nul 2>&1
    if !errorlevel!==0 (
        set "SSHPASS_CMD=sshpass -p "%RPI_PASS%""
    ) else (
        echo  [NOTE] sshpass not found - SSH will prompt for password interactively.
        echo         Install sshpass or set up SSH keys to avoid this.
        echo.
    )
)

REM ── Validate source ────────────────────────────────────────
if not exist "%WS_DIR%\app.py" (
    echo.
    echo  [ERROR] KenpoFlashcardsWebServer not found at:
    echo    %WS_DIR%
    echo.
    echo  Ensure this tool is at: sidscri-apps\tools\SyncTool-WebServerToRPi\
    pause & exit /b 1
)

REM ── Banner ─────────────────────────────────────────────────
echo.
echo  ====================================================
echo   SyncTool: WebServer to RPi  ^(v%TOOL_VER% build %TOOL_BUILD%^)
echo  ====================================================
echo.
echo   WebServer:  %WS_DIR%
echo   RPi target: %RPI_USER%@%RPI_HOST% (SSH port %RPI_PORT%)
echo   Web UI:     %RPI_WEB_URL%
echo   Mode:       %MODE%
if "%DRY_RUN%"=="1" echo   ** DRY RUN - no changes will be made **
echo.

REM ── Dispatch ───────────────────────────────────────────────
if "%MODE%"=="status"  goto :do_status
if "%MODE%"=="restart" goto :do_restart
if "%MODE%"=="version" goto :do_version
if "%MODE%"=="code"    goto :do_code
if "%MODE%"=="data"    goto :do_data
if "%MODE%"=="all"     goto :do_all
goto :show_help

REM ════════════════════════════════════════════════════════════
REM  STATUS
REM ════════════════════════════════════════════════════════════
:do_status
echo  [INFO] Checking RPi service status...
echo.
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "systemctl status %RPI_SERVICE% --no-pager -l 2>/dev/null; echo; echo '--- Version ---'; cat %RPI_INSTALL%/app/version.json 2>/dev/null || cat %RPI_INSTALL%/version.json 2>/dev/null || echo 'version.json not found'; echo; echo '--- Data size ---'; du -sh %RPI_INSTALL%/data 2>/dev/null || echo 'data dir not found'; echo '--- Uptime ---'; uptime"
echo.
goto :done

REM ════════════════════════════════════════════════════════════
REM  RESTART
REM ════════════════════════════════════════════════════════════
:do_restart
echo  [INFO] Restarting RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl restart %RPI_SERVICE% && sleep 2 && systemctl is-active %RPI_SERVICE% && echo [OK] Service running || echo [FAIL] Service not running"
goto :done

REM ════════════════════════════════════════════════════════════
REM  VERSION
REM ════════════════════════════════════════════════════════════
:do_version
echo  --- Local WebServer ---
if exist "%WS_DIR%\version.json" (
    type "%WS_DIR%\version.json"
) else (
    echo  version.json not found locally
)
echo.
echo  --- RPi WebServer ---
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "cat %RPI_INSTALL%/app/version.json 2>/dev/null || cat %RPI_INSTALL%/version.json 2>/dev/null || echo 'Not found'"
echo.
echo  --- RPi Package ---
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "cat %RPI_INSTALL%/repo/AdvancedFlashcardsWebServer_RPi/version.json 2>/dev/null || echo 'Not found'"
echo.
goto :done

REM ════════════════════════════════════════════════════════════
REM  PUSH CODE
REM ════════════════════════════════════════════════════════════
:do_code
echo  [INFO] Pushing WebServer CODE to RPi...
echo.

if "%DRY_RUN%"=="1" (
    echo  [DRY-RUN] Source:  %WS_DIR%\
    echo  [DRY-RUN] Target:  %RPI_USER%@%RPI_HOST%:%RPI_INSTALL%/app/
    echo  [DRY-RUN] Exclude: data\, logs\, .venv\, __pycache__\, *.bat, *.pyc, .env.rpi
    echo  [DRY-RUN] Service: stop ^> upload ^> pip install ^> restart
    goto :done
)

echo  [1/4] Stopping RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl stop %RPI_SERVICE% || true"

echo  [2/4] Staging code...
set "STAGE=%TEMP%\_synctool_rpi_%RANDOM%"
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%"
robocopy "%WS_DIR%" "%STAGE%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS ^
    /XD "data" "logs" ".venv" "__pycache__" ".git" /XF "*.bat" "*.pyc" ".env.rpi" >nul 2>&1

echo  [3/4] Uploading code to RPi...
%SSHPASS_CMD% scp -P %RPI_PORT% -r "%STAGE%\." "%RPI_USER%@%RPI_HOST%:%RPI_INSTALL%/app/"
if errorlevel 1 (
    echo  [ERROR] Upload failed. Check SSH connectivity.
    rmdir /s /q "%STAGE%" >nul 2>&1
    goto :fail
)
rmdir /s /q "%STAGE%" >nul 2>&1

echo  [3b/4] Checking Python dependencies...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "if [ -f %RPI_INSTALL%/app/requirements.txt ] && [ -x %RPI_INSTALL%/.venv/bin/pip ]; then %RPI_INSTALL%/.venv/bin/pip install -r %RPI_INSTALL%/app/requirements.txt -q && echo [OK] deps up to date; else echo [WARN] venv not found - run setup_rpi.sh; fi"

echo  [4/4] Restarting RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl start %RPI_SERVICE% && sleep 2 && systemctl is-active %RPI_SERVICE% && echo [OK] Service running || echo [FAIL] Service not running"

echo.
echo  [DONE] Code pushed to RPi.
goto :done

REM ════════════════════════════════════════════════════════════
REM  PUSH DATA
REM ════════════════════════════════════════════════════════════
:do_data
echo  [INFO] Pushing WebServer DATA to RPi...
echo.

set "LOCAL_DATA=%WS_DIR%\data"
if not exist "%LOCAL_DATA%\" (
    echo  [ERROR] Local data dir not found: %LOCAL_DATA%
    goto :fail
)

set "FILE_COUNT=0"
for /r "%LOCAL_DATA%" %%f in (*) do set /a FILE_COUNT+=1
echo   Source:  %LOCAL_DATA%
echo   Target:  %RPI_USER%@%RPI_HOST%:%RPI_INSTALL%/data/
echo   Files:   %FILE_COUNT%
echo.

if "%DRY_RUN%"=="1" (
    echo  [DRY-RUN] Would push %FILE_COUNT% files - RPi backup first
    goto :done
)

set /p CONFIRM="  Push data to RPi? This OVERWRITES RPi data. (y/N): "
if /i not "%CONFIRM%"=="y" ( echo  Cancelled. & goto :done )

echo  [1/3] Stopping RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl stop %RPI_SERVICE% || true"

echo  [2/3] Creating backup on RPi...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "mkdir -p %RPI_INSTALL%/backups && cd %RPI_INSTALL% && tar -czf backups/data_pre_sync_$(date +%%Y%%m%%d_%%H%%M%%S).tar.gz data/ 2>/dev/null && echo backup_done"

echo  [3/3] Uploading data...
%SSHPASS_CMD% scp -P %RPI_PORT% -r "%LOCAL_DATA%\." "%RPI_USER%@%RPI_HOST%:%RPI_INSTALL%/data/"
if errorlevel 1 (
    echo  [ERROR] Upload failed!
    %SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl start %RPI_SERVICE%"
    goto :fail
)

echo  [INFO] Restarting RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl start %RPI_SERVICE% && sleep 2 && systemctl is-active %RPI_SERVICE% && echo [OK] Service running || echo [FAIL] Service not running"

echo.
echo  [DONE] Data pushed to RPi.
goto :done

REM ════════════════════════════════════════════════════════════
REM  PUSH ALL
REM ════════════════════════════════════════════════════════════
:do_all
echo  [INFO] Pushing CODE + DATA to RPi...
echo.

if "%DRY_RUN%"=="1" (
    echo  [DRY-RUN] Would push code from: %WS_DIR%\
    echo  [DRY-RUN] Would push data from: %WS_DIR%\data\
    echo  [DRY-RUN] RPi backup would be created first
    goto :done
)

set /p CONFIRM="  Push CODE + DATA to RPi? This OVERWRITES RPi data. (y/N): "
if /i not "%CONFIRM%"=="y" ( echo  Cancelled. & goto :done )

echo  [1/6] Stopping RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl stop %RPI_SERVICE% || true"

echo  [2/6] Creating backup on RPi...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "mkdir -p %RPI_INSTALL%/backups && cd %RPI_INSTALL% && tar -czf backups/data_pre_sync_$(date +%%Y%%m%%d_%%H%%M%%S).tar.gz data/ 2>/dev/null && echo backup_done"

echo  [3/6] Staging code...
set "STAGE=%TEMP%\_synctool_rpi_%RANDOM%"
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%"
robocopy "%WS_DIR%" "%STAGE%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS ^
    /XD "data" "logs" ".venv" "__pycache__" ".git" /XF "*.bat" "*.pyc" ".env.rpi" >nul 2>&1

echo  [4/6] Uploading code...
%SSHPASS_CMD% scp -P %RPI_PORT% -r "%STAGE%\." "%RPI_USER%@%RPI_HOST%:%RPI_INSTALL%/app/"
rmdir /s /q "%STAGE%" >nul 2>&1

echo  [4b/6] Checking Python dependencies...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "if [ -f %RPI_INSTALL%/app/requirements.txt ] && [ -x %RPI_INSTALL%/.venv/bin/pip ]; then %RPI_INSTALL%/.venv/bin/pip install -r %RPI_INSTALL%/app/requirements.txt -q && echo [OK] deps up to date; else echo [WARN] venv not found; fi"

echo  [5/6] Uploading data...
%SSHPASS_CMD% scp -P %RPI_PORT% -r "%WS_DIR%\data\." "%RPI_USER%@%RPI_HOST%:%RPI_INSTALL%/data/"
if errorlevel 1 (
    echo  [ERROR] Upload failed!
    %SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl start %RPI_SERVICE%"
    goto :fail
)

echo  [6/6] Restarting RPi service...
%SSHPASS_CMD% ssh -p %RPI_PORT% "%RPI_USER%@%RPI_HOST%" "sudo systemctl start %RPI_SERVICE% && sleep 2 && systemctl is-active %RPI_SERVICE% && echo [OK] Service running || echo [FAIL] Service not running"

echo.
echo  [DONE] Code + Data pushed to RPi.
goto :done

REM ════════════════════════════════════════════════════════════
REM  HELP
REM ════════════════════════════════════════════════════════════
:show_help
echo.
echo  SyncTool: WebServer to RPi  ^(v%TOOL_VER% build %TOOL_BUILD%^)
echo.
echo  Push WebServer code and/or data from Windows to Raspberry Pi.
echo.
echo  Usage:
echo    SyncTool-WebServerToRPi.bat [rpi-ip] [options]
echo.
echo    Double-click with no args: prompts for IP, user, password.
echo    Settings saved to rpi_config.txt after first run.
echo    Delete rpi_config.txt to re-prompt for all settings.
echo.
echo  rpi_config.txt format:
echo    ip=192.168.0.205
echo    user=sidscri
echo    port=22
echo    pass=            (blank = SSH prompts each time)
echo.
echo  Sync Modes:
echo    --code       Push code only (default)
echo    --data       Push data only (with confirmation)
echo    --all        Push code + data (with confirmation)
echo.
echo  Info Modes:
echo    --status     Show RPi service status
echo    --restart    Restart RPi service
echo    --version    Compare local vs RPi versions
echo.
echo  Options:
echo    --dry-run    Preview what would be synced
echo    --save       Force re-save connection settings
echo    --user ^<u^>   RPi SSH user (overrides config)
echo    --port ^<p^>   RPi SSH port (overrides config)
echo    -h, --help   Show this help
echo.
echo  Password note:
echo    Native Windows SSH cannot pass passwords on the command line.
echo    If pass= is set in rpi_config.txt and sshpass is installed,
echo    it will be used automatically. Otherwise SSH will prompt.
echo    Recommended: set up SSH key auth to avoid passwords entirely.
echo    See: ssh-keygen then ssh-copy-id %RPI_USER%@^<rpi-ip^>
echo.
pause
exit /b 0

:done
echo.
echo  RPi web UI: %RPI_WEB_URL%
echo.
pause
exit /b 0

:fail
echo.
echo  [FAILED] See errors above.
pause
exit /b 1
