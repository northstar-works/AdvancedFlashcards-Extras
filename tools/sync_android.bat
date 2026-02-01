@echo off
REM ============================================================
REM  WebServer → Android Sync Tool
REM  Syncs version metadata and generates feature parity report
REM ============================================================
setlocal

REM Get the directory where this script is located (tools folder)
set TOOLS_DIR=%~dp0
set TOOLS_DIR=%TOOLS_DIR:~0,-1%

REM Default paths (sibling folders to tools)
set DEFAULT_WEBSERVER=%TOOLS_DIR%\..\KenpoFlashcardsWebServer
set DEFAULT_ANDROID=%TOOLS_DIR%\..\KenpoFlashcardsProject-v2

REM Check if Python is available
where python >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo ERROR: Python not found in PATH
    echo Please install Python 3.8+ and add it to your PATH
    pause
    exit /b 1
)

REM Parse arguments
set WEBSERVER_FOLDER=
set ANDROID_FOLDER=
set DRY_RUN=
set LEVEL=

:parse_args
if "%~1"=="" goto done_parsing
if "%~1"=="--dry-run" (
    set DRY_RUN=--dry-run
    shift
    goto parse_args
)
if "%~1"=="-n" (
    set DRY_RUN=--dry-run
    shift
    goto parse_args
)
if "%~1"=="--level" (
    if "%~2"=="" goto done_parsing
    set LEVEL=--level %~2
    shift
    shift
    goto parse_args
)
if "%~1"=="-l" (
    if "%~2"=="" goto done_parsing
    set LEVEL=--level %~2
    shift
    shift
    goto parse_args
)
if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%WEBSERVER_FOLDER%"=="" (
    set WEBSERVER_FOLDER=%~1
    shift
    goto parse_args
)
if "%ANDROID_FOLDER%"=="" (
    set ANDROID_FOLDER=%~1
    shift
    goto parse_args
)
shift
goto parse_args
:done_parsing

REM Use defaults if not specified
if "%WEBSERVER_FOLDER%"=="" set WEBSERVER_FOLDER=%DEFAULT_WEBSERVER%
if "%ANDROID_FOLDER%"=="" set ANDROID_FOLDER=%DEFAULT_ANDROID%

REM Validate
if not exist "%WEBSERVER_FOLDER%" (
    echo.
    echo ERROR: WebServer folder not found: %WEBSERVER_FOLDER%
    echo.
    goto show_help
)
if not exist "%WEBSERVER_FOLDER%\version.json" (
    echo.
    echo ERROR: Not a valid WebServer folder (missing version.json)
    pause
    exit /b 1
)
if not exist "%ANDROID_FOLDER%" (
    echo.
    echo ERROR: Android folder not found: %ANDROID_FOLDER%
    echo.
    goto show_help
)
if not exist "%ANDROID_FOLDER%\app\build.gradle" (
    echo.
    echo ERROR: Not a valid Android project (missing app\build.gradle)
    pause
    exit /b 1
)

REM Run
echo.
echo ============================================================
echo  Starting WebServer to Android Sync...
echo ============================================================
echo.
echo  WebServer: %WEBSERVER_FOLDER%
echo  Android:   %ANDROID_FOLDER%
echo  Backups:   %TOOLS_DIR%\sync_backups\
echo.
python "%TOOLS_DIR%\sync_webserver_to_android.py" "%WEBSERVER_FOLDER%" "%ANDROID_FOLDER%" %DRY_RUN% %LEVEL%

if %errorlevel% neq 0 (
    echo.
    echo Sync failed with error code %errorlevel%
    pause
    exit /b %errorlevel%
)

echo.
pause
exit /b 0

:show_help
echo.
echo ============================================================
echo  WebServer to Android Sync Tool
echo ============================================================
echo.
echo Usage: sync_android.bat [webserver_folder] [android_folder] [options]
echo.
echo Arguments (optional - uses sibling folder defaults):
echo   webserver_folder - Path to KenpoFlashcardsWebServer
echo   android_folder   - Path to KenpoFlashcardsProject-v2
echo.
echo Defaults:
echo   webserver = ..\KenpoFlashcardsWebServer
echo   android   = ..\KenpoFlashcardsProject-v2
echo.
echo Options:
echo   --dry-run, -n       Preview changes without applying
echo   --level N, -l N     Upgrade level: 1=patch, 2=minor, 3=major
echo   --help, -h          Show this help
echo.
echo Examples:
echo   sync_android.bat                           (defaults)
echo   sync_android.bat --dry-run                 (preview)
echo   sync_android.bat --level 2                 (minor bump)
echo   sync_android.bat ..\WS ..\Android --dry-run
echo.
pause
exit /b 0
