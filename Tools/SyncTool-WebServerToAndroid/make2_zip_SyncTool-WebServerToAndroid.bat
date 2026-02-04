@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM  make2_zip_SyncTool-WebServerToAndroid.bat
REM  - Writes ZIP to: <repo_root>\logs\zips\
REM  - Writes zip + logs to: <repo_root>\logs\zips\
REM  - ZIP contains a versioned root folder:
REM      SyncTool-WebServerToAndroid-vX.X.X_bY\...
REM ============================================================

set "TOOL_DIR=%~dp0"
set "TOOL_DIR=%TOOL_DIR:~0,-1%"

for %%I in ("%TOOL_DIR%\..\..") do set "REPO_ROOT=%%~fI"

set "LOGDIR=%REPO_ROOT%\logs\zips"
if not exist "%LOGDIR%" mkdir "%LOGDIR%" >nul 2>&1

set "TS=%DATE:~10,4%%DATE:~4,2%%DATE:~7,2%_%TIME:~0,2%%TIME:~3,2%%TIME:~6,2%"
set "TS=%TS: =0%"

set "LOGFILE=%LOGDIR%\make2_zip_SyncTool-WebServerToAndroid_%TS%.log"

echo ===========================================================>>"%LOGFILE%"
echo START %DATE% %TIME%>>"%LOGFILE%"
echo TOOL_DIR=%TOOL_DIR%>>"%LOGFILE%"
echo REPO_ROOT=%REPO_ROOT%>>"%LOGFILE%"
echo ===========================================================>>"%LOGFILE%"

set "VERJSON=%TOOL_DIR%\version.json"
if not exist "%VERJSON%" (
  echo [ERROR] version.json missing: %VERJSON%
  echo [ERROR] version.json missing: %VERJSON%>>"%LOGFILE%"
  exit /b 1
)

REM Parse version/build from JSON using PowerShell (robust)
for /f "usebackq delims=" %%V in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$j = Get-Content -Raw '%VERJSON%' | ConvertFrom-Json; $j.version"`) do set "VER=%%V"

for /f "usebackq delims=" %%B in (`powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$j = Get-Content -Raw '%VERJSON%' | ConvertFrom-Json; $j.build"`) do set "BUILD=%%B"

if "%VER%"=="" (
  echo [ERROR] Could not read version from version.json
  echo [ERROR] Could not read version from version.json>>"%LOGFILE%"
  exit /b 1
)
if "%BUILD%"=="" (
  echo [ERROR] Could not read build from version.json
  echo [ERROR] Could not read build from version.json>>"%LOGFILE%"
  exit /b 1
)

set "TOOL_NAME=SyncTool-WebServerToAndroid"
set "ROOT_NAME=%TOOL_NAME%-v%VER%_b%BUILD%"
set "ZIP_NAME=%ROOT_NAME%.zip"
set "OUTDIR=%REPO_ROOT%\logs\zips"
set "ZIP_PATH=%OUTDIR%\%ZIP_NAME%"

REM Staging folder (keeps zip root folder versioned)
set "STAGE_ROOT=%TOOL_DIR%\_zip_staging"
set "STAGE_DIR=%STAGE_ROOT%\%ROOT_NAME%"

if exist "%STAGE_ROOT%" rmdir /s /q "%STAGE_ROOT%" >nul 2>&1
mkdir "%STAGE_DIR%" >nul 2>&1

echo [INFO] Staging to: %STAGE_DIR%
echo [INFO] Creating : %ZIP_PATH%
echo [INFO] Staging to: %STAGE_DIR%>>"%LOGFILE%"
echo [INFO] Creating : %ZIP_PATH%>>"%LOGFILE%"

REM Copy tool into staged versioned folder, excluding junk
robocopy "%TOOL_DIR%" "%STAGE_DIR%" /MIR ^
  /XD "%TOOL_DIR%\output" "%TOOL_DIR%\logs" "%TOOL_DIR%\__pycache__" "%TOOL_DIR%\sync_backups" "%TOOL_DIR%\.git" "%TOOL_DIR%\_zip_staging" ^
  /XF "*.log" "*.zip" > "%LOGFILE%.robocopy.txt"

if errorlevel 8 (
  echo [ERROR] Robocopy failed.
  echo [ERROR] Robocopy failed.>>"%LOGFILE%"
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
  "$zipPath = '%ZIP_PATH%';" ^
  "$src = '%STAGE_DIR%';" ^
  "if (Test-Path $zipPath) { Remove-Item -Force $zipPath };" ^
  "Compress-Archive -Path $src -DestinationPath $zipPath -Force;" ^
  "Write-Host ('[OK] Wrote: ' + $zipPath);" >> "%LOGFILE%" 2>&1

if errorlevel 1 (
  echo [ERROR] Zip failed.
  echo [ERROR] Zip failed.>>"%LOGFILE%"
  exit /b 1
)

rmdir /s /q "%STAGE_ROOT%" >nul 2>&1

echo [OK] Wrote: %ZIP_PATH%
echo [OK] Wrote: %ZIP_PATH%>>"%LOGFILE%"
exit /b 0
