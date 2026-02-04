@echo off
REM ============================================================
REM  KenpoFlashcards Web Server → Packaged Sync Tool
REM  (WebServer → Packaged one-way sync; NO_BACKUPS build)
REM
REM  Expected location (recommended):
REM    sidscri-apps\tools\SyncTool-WebServerToPackaged\sync_webserver.bat
REM    OR sidscri-apps\Tools\SyncTool-WebServerToPackaged\sync_webserver.bat
REM
REM  Defaults are resolved from PROJECT ROOT (sidscri-apps\):
REM    WebServer:  <root>\KenpoFlashcardsWebServer
REM    Packaged:   <root>\KenpoFlashcardsWebServer_Packaged
REM    Output:     <root>\KenpoFlashcardsWebServer_Packaged_Synced   (default)
REM
REM  Logs:
REM    <root>\logs\zips\sync_webserver_to_packaged_YYYYMMDD_HHMMSS.log
REM ============================================================
setlocal EnableExtensions EnableDelayedExpansion

REM --- Tool dir (this BAT's folder)
set "TOOL_DIR=%~dp0"
if "%TOOL_DIR:~-1%"=="\" set "TOOL_DIR=%TOOL_DIR:~0,-1%"

REM --- Project root is TWO levels up from ...\tools\SyncTool-WebServerToPackaged
for %%I in ("%TOOL_DIR%\..\..") do set "PROJECT_ROOT=%%~fI"

REM --- Defaults
set "DEFAULT_WEBSERVER=%PROJECT_ROOT%\KenpoFlashcardsWebServer"
set "DEFAULT_PACKAGED=%PROJECT_ROOT%\KenpoFlashcardsWebServer_Packaged"

REM --- Log folder
set "LOG_DIR=%PROJECT_ROOT%\logs\zips"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%" >nul 2>&1

REM --- Zip output destination (repo root)
set "ZIP_OUT_DIR=%PROJECT_ROOT%"

REM --- Parse args
set "WEBSERVER_FOLDER="
set "PACKAGED_FOLDER="
set "DRY_RUN="
set "OUTPUT_MODE=--output synced"
set "SHOW_HELP="

:parse_args
if "%~1"=="" goto done_parsing

if /I "%~1"=="--help"  set "SHOW_HELP=1" & shift & goto parse_args
if /I "%~1"=="-h"      set "SHOW_HELP=1" & shift & goto parse_args

if /I "%~1"=="--dry-run" set "DRY_RUN=--dry-run" & shift & goto parse_args
if /I "%~1"=="-n"        set "DRY_RUN=--dry-run" & shift & goto parse_args

if /I "%~1"=="--synced"  set "OUTPUT_MODE=--output synced"  & shift & goto parse_args
if /I "%~1"=="--inplace" set "OUTPUT_MODE=--output inplace" & shift & goto parse_args

if /I "%~1"=="--output" (
    if "%~2"=="" goto done_parsing
    set "OUTPUT_MODE=--output %~2"
    shift
    shift
    goto parse_args
)

if "%WEBSERVER_FOLDER%"=="" (
    set "WEBSERVER_FOLDER=%~1"
    shift
    goto parse_args
)
if "%PACKAGED_FOLDER%"=="" (
    set "PACKAGED_FOLDER=%~1"
    shift
    goto parse_args
)

shift
goto parse_args

:done_parsing

if defined SHOW_HELP goto show_help

REM --- Defaults
if "%WEBSERVER_FOLDER%"=="" set "WEBSERVER_FOLDER=%DEFAULT_WEBSERVER%"
if "%PACKAGED_FOLDER%"=="" set "PACKAGED_FOLDER=%DEFAULT_PACKAGED%"

REM --- Normalize to full paths
for %%I in ("%WEBSERVER_FOLDER%") do set "WEBSERVER_FOLDER=%%~fI"
for %%I in ("%PACKAGED_FOLDER%") do set "PACKAGED_FOLDER=%%~fI"

REM --- Check python
where python >nul 2>&1
if errorlevel 1 (
    echo.
    echo ERROR: Python not found in PATH
    echo Please install Python 3.8+ and add it to your PATH.
    echo.
    pause
    exit /b 1
)

REM --- Validate folders
if not exist "%WEBSERVER_FOLDER%\" (
    echo.
    echo ERROR: Web server folder not found: %WEBSERVER_FOLDER%
    echo Expected default: %DEFAULT_WEBSERVER%
    echo.
    goto show_help
)

if not exist "%WEBSERVER_FOLDER%\version.json" (
    echo.
    echo ERROR: Not a valid web server project folder (missing version.json)
    echo        %WEBSERVER_FOLDER%
    echo.
    pause
    exit /b 1
)

if not exist "%PACKAGED_FOLDER%\" (
    echo.
    echo ERROR: Packaged folder not found: %PACKAGED_FOLDER%
    echo Expected default: %DEFAULT_PACKAGED%
    echo.
    goto show_help
)

REM --- Timestamped log
set "TS=%DATE:~-4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TS=%TS: =0%"
set "RUNLOG=%LOG_DIR%\sync_webserver_to_packaged_%TS%.log"

echo ============================================================ > "%RUNLOG%"
echo  KenpoFlashcards Web Server -> Packaged Sync Tool            >> "%RUNLOG%"
echo ============================================================ >> "%RUNLOG%"
echo PROJECT_ROOT=%PROJECT_ROOT%                                 >> "%RUNLOG%"
echo Source=%WEBSERVER_FOLDER%                                   >> "%RUNLOG%"
echo Destination=%PACKAGED_FOLDER%                               >> "%RUNLOG%"
echo DRY_RUN=%DRY_RUN%                                           >> "%RUNLOG%"
echo OUTPUT_MODE=%OUTPUT_MODE%                                   >> "%RUNLOG%"
echo.                                                           >> "%RUNLOG%"

echo.
echo ============================================================
echo  Starting Sync...
echo ============================================================
echo.
echo  ProjectRoot: %PROJECT_ROOT%
echo  Source:      %WEBSERVER_FOLDER%
echo  Destination: %PACKAGED_FOLDER%
echo  Log:         %RUNLOG%
echo.

python "%TOOL_DIR%\sync_webserver_to_packaged.py" "%WEBSERVER_FOLDER%" "%PACKAGED_FOLDER%" %DRY_RUN% %OUTPUT_MODE% >> "%RUNLOG%" 2>&1
set "EC=%ERRORLEVEL%"

if not "%EC%"=="0" (
    echo.
    echo Sync failed with error code %EC%
    echo See log: %RUNLOG%
    echo.
    pause
    exit /b %EC%
)

REM --- Auto-zip the resulting output folder into repo root
set "OUT_DIR="
if /I "%OUTPUT_MODE%"=="--output synced"  set "OUT_DIR=%PROJECT_ROOT%\KenpoFlashcardsWebServer_Packaged_Synced"
if /I "%OUTPUT_MODE%"=="--output inplace" set "OUT_DIR=%PACKAGED_FOLDER%"

if defined OUT_DIR (
    if /I "%DRY_RUN%"=="--dry-run" (
        echo.
        echo (Dry-run) Skip zip creation.
        echo (Dry-run) Skip zip creation.>>"%RUNLOG%"
    ) else (
        for %%I in ("%OUT_DIR%") do set "OUT_NAME=%%~nxI"

        REM Read version/build from version.json (PowerShell JSON parser)
        set "VB=unknown|"
        for /f "usebackq delims=" %%V in (`powershell -NoProfile -Command "try{ $j=Get-Content -Raw '%OUT_DIR%\\version.json' | ConvertFrom-Json; \"$($j.version)|$($j.build)\" } catch { 'unknown|' }"`) do set "VB=%%V"
        for /f "tokens=1,2 delims=|" %%A in ("%VB%") do (
            set "VER=%%A"
            set "BUILD=%%B"
        )
        if not defined VER set "VER=unknown"

        set "ZIP_NAME=%OUT_NAME%-v%VER%"
        if defined BUILD set "ZIP_NAME=%ZIP_NAME%_b%BUILD%"
        set "ZIP_NAME=%ZIP_NAME%_%TS%.zip"
        set "ZIP_PATH=%ZIP_OUT_DIR%\%ZIP_NAME%"

        echo.
        echo Creating zip: %ZIP_PATH%
        echo Creating zip: %ZIP_PATH%>>"%RUNLOG%"

        powershell -NoProfile -Command "Compress-Archive -Path '%OUT_DIR%' -DestinationPath '%ZIP_PATH%' -Force" >>"%RUNLOG%" 2>&1
        if not "%ERRORLEVEL%"=="0" (
            echo [WARN] Zip creation failed. See log: %RUNLOG%
            echo [WARN] Zip creation failed.>>"%RUNLOG%"
        ) else (
            echo Zip created: %ZIP_PATH%
            echo Zip created: %ZIP_PATH%>>"%RUNLOG%"
        )
    )
)

echo.
echo Sync complete.
echo See log: %RUNLOG%
echo.
pause
exit /b 0

:show_help
echo.
echo ============================================================
echo  KenpoFlashcards Web Server → Packaged Sync Tool
echo ============================================================
echo.
echo Usage: sync_webserver.bat [webserver_folder] [packaged_folder] [options]
echo.
echo Defaults:
echo   webserver_folder = %DEFAULT_WEBSERVER%
echo   packaged_folder  = %DEFAULT_PACKAGED%
echo   output           = synced  (default)
echo.
echo Options:
echo   --dry-run, -n    Preview changes without applying them
echo   --inplace        Write changes into Packaged (in-place)
echo   --synced         Write into *_Packaged_Synced (DEFAULT)
echo   --output MODE    MODE is: synced or inplace
echo   --help, -h       Show this help
echo.
echo Logs:
echo   %LOG_DIR%
echo.
pause
exit /b 1
