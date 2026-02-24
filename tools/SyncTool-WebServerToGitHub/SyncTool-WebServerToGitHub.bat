@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM SyncTool-WebServerToGitHub.bat
REM Push KenpoFlashcardsWebServer changes to GitHub repo
REM
REM Place in: C:\Path\To\KenpoFlashcardsWebServer\ (or run from anywhere with full paths)
REM
REM Usage:
REM   SyncTool-WebServerToGitHub.bat [options]
REM
REM Options:
REM   --dry-run     Show what would be copied (no changes)
REM   --no-commit   Copy files but don't git commit
REM   --no-push     Commit but don't git push to origin
REM   --auto        Skip all confirmations (auto-commit + push)
REM   --help, -h    Show this help
REM ============================================================

set "TOOL_VER=1.0.0"
set "TOOL_BUILD=1"

REM ── Defaults ───────────────────────────────────────────────
set "DRY_RUN=0"
set "NO_COMMIT=0"
set "NO_PUSH=0"
set "AUTO=0"

REM ── Parse arguments ────────────────────────────────────────
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--dry-run"   ( set "DRY_RUN=1"   & shift & goto :parse_args )
if /i "%~1"=="--no-commit" ( set "NO_COMMIT=1" & shift & goto :parse_args )
if /i "%~1"=="--no-push"   ( set "NO_PUSH=1"   & shift & goto :parse_args )
if /i "%~1"=="--auto"      ( set "AUTO=1"      & shift & goto :parse_args )
if /i "%~1"=="--help"      goto :show_help
if /i "%~1"=="-h"          goto :show_help
echo [WARN] Unknown option ignored: %~1
shift & goto :parse_args
:args_done

REM ── Locate WebServer and monorepo ──────────────────────────
REM Try to auto-detect if we're in the WebServer folder
set "WS_DIR="
set "MONO_ROOT="

REM If we're in a folder with app.py, assume this is the WebServer
if exist "app.py" (
    set "WS_DIR=%CD%"
) else if exist "KenpoFlashcardsWebServer\app.py" (
    set "WS_DIR=%CD%\KenpoFlashcardsWebServer"
)

REM If not found, prompt
if "%WS_DIR%"=="" (
    echo.
    echo  [INFO] Could not auto-detect KenpoFlashcardsWebServer location.
    echo.
    set /p WS_DIR="  Enter full path to KenpoFlashcardsWebServer folder: "
    if "!WS_DIR!"=="" (
        echo  [ERROR] No path entered. Exiting.
        pause & exit /b 1
    )
)

REM Validate WebServer folder
if not exist "%WS_DIR%\app.py" (
    echo.
    echo  [ERROR] app.py not found in:
    echo    %WS_DIR%
    echo.
    echo  Please ensure the path is correct.
    pause & exit /b 1
)

REM Locate monorepo — look for sidscri-apps folder with KenpoFlashcardsWebServer inside
set "SEARCH_ROOT=C:\Users\%USERNAME%\Documents\GitHub"
for /d %%D in ("%SEARCH_ROOT%\*") do (
    if exist "%%D\KenpoFlashcardsWebServer\app.py" (
        if exist "%%D\.git" (
            set "MONO_ROOT=%%D"
            goto :found_mono
        )
    )
)

:found_mono
if "%MONO_ROOT%"=="" (
    echo.
    echo  [WARN] Could not auto-detect monorepo (sidscri-apps).
    echo.
    set /p MONO_ROOT="  Enter full path to monorepo root (with .git): "
    if "!MONO_ROOT!"=="" (
        echo  [ERROR] No path entered. Exiting.
        pause & exit /b 1
    )
)

REM Validate monorepo
if not exist "%MONO_ROOT%\.git" (
    echo.
    echo  [ERROR] Not a git repository:
    echo    %MONO_ROOT%
    pause & exit /b 1
)

set "MONO_WS=%MONO_ROOT%\KenpoFlashcardsWebServer"
if not exist "%MONO_WS%" (
    echo.
    echo  [ERROR] KenpoFlashcardsWebServer not found in monorepo at:
    echo    %MONO_WS%
    pause & exit /b 1
)

REM ── Banner ─────────────────────────────────────────────────
echo.
echo  ====================================================
echo   SyncTool: WebServer to GitHub  ^(v%TOOL_VER% build %TOOL_BUILD%^)
echo  ====================================================
echo.
echo   Source:      %WS_DIR%
echo   Destination: %MONO_WS%
echo   Repo:        %MONO_ROOT%
if "%DRY_RUN%"=="1" echo   ** DRY RUN - no changes will be made **
echo.

REM ── Count files to sync ────────────────────────────────────
set "FILE_COUNT=0"
for /r "%WS_DIR%" %%f in (*) do set /a FILE_COUNT+=1

echo   Files in source: %FILE_COUNT%
echo.

if "%AUTO%"=="0" (
    set /p CONFIRM="  Sync WebServer to GitHub monorepo? (y/N): "
    if /i not "!CONFIRM!"=="y" (
        echo  Cancelled.
        pause & exit /b 0
    )
)

REM ── Sync files ─────────────────────────────────────────────
if "%DRY_RUN%"=="1" (
    echo  [DRY-RUN] Would robocopy:
    echo    FROM: %WS_DIR%
    echo    TO:   %MONO_WS%
    echo    Exclude: .venv\, __pycache__\, *.pyc, *.bat, logs\, data\
    pause & exit /b 0
)

echo  [1/3] Syncing files...
robocopy "%WS_DIR%" "%MONO_WS%" /MIR /R:1 /W:1 /NFL /NDL /NP ^
    /XD ".venv" "__pycache__" "logs" "data" ".git" /XF "*.pyc" "*.bat" >nul 2>&1

if errorlevel 8 (
    echo  [ERROR] Robocopy failed with error level !errorlevel!
    pause & exit /b 1
)

echo  [DONE] Files synced.
echo.

if "%NO_COMMIT%"=="1" (
    echo  [INFO] --no-commit specified. Skipping git commit.
    echo.
    echo  You can commit manually:
    echo    cd %MONO_ROOT%
    echo    git add KenpoFlashcardsWebServer
    echo    git commit -m "Update WebServer"
    pause & exit /b 0
)

REM ── Git commit ─────────────────────────────────────────────
cd /d "%MONO_ROOT%"

REM Check if there are changes
git diff --quiet KenpoFlashcardsWebServer
if !errorlevel!==0 (
    echo  [INFO] No changes detected. Nothing to commit.
    pause & exit /b 0
)

echo  [2/3] Staging changes...
git add KenpoFlashcardsWebServer

REM Read version from version.json for commit message
set "COMMIT_MSG=Update WebServer"
if exist "%MONO_WS%\version.json" (
    for /f "tokens=2 delims=:" %%V in ('type "%MONO_WS%\version.json" ^| findstr /i "version"') do (
        set "VER_LINE=%%V"
        set "VER_LINE=!VER_LINE:"=!"
        set "VER_LINE=!VER_LINE:,=!"
        set "VER_LINE=!VER_LINE: =!"
        set "COMMIT_MSG=Update WebServer to v!VER_LINE!"
        goto :got_version
    )
)
:got_version

echo  [INFO] Committing with message: "%COMMIT_MSG%"
git commit -m "%COMMIT_MSG%" --quiet

if errorlevel 1 (
    echo  [ERROR] Git commit failed.
    pause & exit /b 1
)

echo  [DONE] Changes committed.
echo.

if "%NO_PUSH%"=="1" (
    echo  [INFO] --no-push specified. Skipping git push.
    echo.
    echo  You can push manually:
    echo    cd %MONO_ROOT%
    echo    git push origin main
    pause & exit /b 0
)

REM ── Git push ───────────────────────────────────────────────
echo  [3/3] Pushing to GitHub...
git push origin main --quiet

if errorlevel 1 (
    echo  [ERROR] Git push failed.
    pause & exit /b 1
)

echo  [DONE] Pushed to GitHub.
echo.
echo  ✓ WebServer synced to GitHub successfully!
echo    RPi can now pull updates with: af-rpi-sync
echo.
pause
exit /b 0

REM ════════════════════════════════════════════════════════════
REM  HELP
REM ════════════════════════════════════════════════════════════
:show_help
echo.
echo  SyncTool: WebServer to GitHub  ^(v%TOOL_VER% build %TOOL_BUILD%^)
echo.
echo  Syncs KenpoFlashcardsWebServer changes to GitHub monorepo,
echo  so af-rpi-sync can pull updates to the Raspberry Pi.
echo.
echo  Usage:
echo    SyncTool-WebServerToGitHub.bat [options]
echo.
echo  Options:
echo    --dry-run     Preview what would be copied
echo    --no-commit   Copy files but don't git commit
echo    --no-push     Commit but don't push to GitHub
echo    --auto        Skip confirmations ^(auto-commit + push^)
echo    -h, --help    Show this help
echo.
echo  Workflow:
echo    1. Detects or prompts for WebServer location
echo    2. Detects or prompts for monorepo ^(sidscri-apps^) location
echo    3. Syncs files via robocopy ^(excludes .venv, logs, data^)
echo    4. Stages changes: git add KenpoFlashcardsWebServer
echo    5. Commits: git commit -m "Update WebServer to vX.Y.Z"
echo    6. Pushes: git push origin main
echo.
echo  After sync, RPi can pull with:
echo    ssh sidscri@192.168.0.205
echo    af-rpi-sync
echo.
pause
exit /b 0
