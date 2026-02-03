@echo off
REM ============================================================
REM  WebServer → Android Sync Tool
REM  Syncs version metadata and generates feature parity report
REM ============================================================
setlocal enabledelayedexpansion

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
    echo  ERROR: Python not found in PATH
    echo  Please install Python 3.8+ and add it to your PATH
    goto :fail
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

REM ── Resolve relative paths to absolute before validation ──
REM This prevents issues with ".." paths and working directory mismatches

pushd "%WEBSERVER_FOLDER%" 2>nul
if %errorlevel% neq 0 (
    echo.
    echo  ERROR: WebServer folder not found: %WEBSERVER_FOLDER%
    echo.
    echo  Expected location: %WEBSERVER_FOLDER%
    echo  The tools folder should be a sibling of KenpoFlashcardsWebServer:
    echo.
    echo    sidscri-apps\
    echo      KenpoFlashcardsWebServer\
    echo      KenpoFlashcardsProject-v2\
    echo      tools\               ^<-- sync_android.bat goes here
    echo.
    goto :fail
)
set WEBSERVER_FOLDER=!CD!
popd

pushd "%ANDROID_FOLDER%" 2>nul
if %errorlevel% neq 0 (
    echo.
    echo  ERROR: Android folder not found: %ANDROID_FOLDER%
    echo.
    echo  Expected location: %ANDROID_FOLDER%
    echo  The tools folder should be a sibling of KenpoFlashcardsProject-v2:
    echo.
    echo    sidscri-apps\
    echo      KenpoFlashcardsWebServer\
    echo      KenpoFlashcardsProject-v2\
    echo      tools\               ^<-- sync_android.bat goes here
    echo.
    goto :fail
)
set ANDROID_FOLDER=!CD!
popd

REM ── Validate required files ──
if not exist "%WEBSERVER_FOLDER%\version.json" (
    echo.
    echo  ERROR: Not a valid WebServer folder (missing version.json)
    echo  Looked in: %WEBSERVER_FOLDER%
    goto :fail
)
if not exist "%ANDROID_FOLDER%\app\build.gradle" (
    echo.
    echo  ERROR: Not a valid Android project (missing app\build.gradle)
    echo  Looked in: %ANDROID_FOLDER%
    goto :fail
)

REM ── Run ──
echo.
echo ============================================================
echo  Starting WebServer to Android Sync...
echo ============================================================
echo.
echo  Tools:     %TOOLS_DIR%
echo  WebServer: %WEBSERVER_FOLDER%
echo  Android:   %ANDROID_FOLDER%
echo  Backups:   %TOOLS_DIR%\sync_backups\
echo.

set PY_SCRIPT=%TOOLS_DIR%\sync_webserver_to_android.py
python "%PY_SCRIPT%" "%WEBSERVER_FOLDER%" "%ANDROID_FOLDER%" %DRY_RUN% %LEVEL%

if %errorlevel% neq 0 (
    echo.
    echo ============================================================
    echo  Sync FAILED  (Python exit code: %errorlevel%)
    echo ============================================================
    echo.
    echo  Check the error messages above. Common issues:
    echo    - Python exception / missing module
    echo    - WebServer CHANGELOG.md format unexpected
    echo    - Android build.gradle format unexpected
    echo.
)

echo.
pause
exit /b 0

:fail
echo.
pause
exit /b 1

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
