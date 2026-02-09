@echo off
setlocal EnableExtensions

REM ============================================================
REM make7_zip_AdvancedFlashcardsWebServer_RPi.bat
REM Put this BAT in: ...\sidscri-apps\
REM Creates ZIP in the SAME folder as this BAT:
REM   AdvancedFlashcardsWebServer_RPi-v<version> v<build>.zip
REM ZIP contents root:
REM   AdvancedFlashcardsWebServer_RPi\...
REM Reads:
REM   .\AdvancedFlashcardsWebServer_RPi\version.json
REM Excludes (recursively, guaranteed):
REM   .venv, __pycache__, *.pyc, .git
REM Writes log:
REM   logs\AdvancedFlashcardsWebServer_RPi.log
REM ============================================================

REM Always run from the BAT's folder (sidscri-apps)
set "BASE=%~dp0"
if "%BASE:~-1%"=="\" set "BASE=%BASE:~0,-1%"
pushd "%BASE%" >nul

set "PROJ=AdvancedFlashcardsWebServer_RPi"
set "SRC=%BASE%\%PROJ%"
set "VERJSON=%SRC%\version.json"

set "LOG=%BASE%\logs\%PROJ%.log"
if not exist "%BASE%\logs" mkdir "%BASE%\logs"
> "%LOG%" echo START %DATE% %TIME%
>>"%LOG%" echo BASE=%BASE%
>>"%LOG%" echo SRC=%SRC%
>>"%LOG%" echo VERJSON=%VERJSON%

if not exist "%SRC%\" (
  >>"%LOG%" echo ERROR: Project folder not found: %SRC%
  goto :fail
)

if not exist "%VERJSON%" (
  >>"%LOG%" echo ERROR: version.json not found: %VERJSON%
  goto :fail
)

REM Find 7-Zip
set "SEVENZIP=%ProgramFiles%\7-Zip\7z.exe"
if not exist "%SEVENZIP%" set "SEVENZIP=%ProgramFiles(x86)%\7-Zip\7z.exe"
>>"%LOG%" echo SEVENZIP=%SEVENZIP%

if not exist "%SEVENZIP%" (
  >>"%LOG%" echo ERROR: 7z.exe not found. Install 7-Zip.
  goto :fail
)

REM ── Parse version and build from version.json ──────────────
set "VER="
set "BUILD="

for /f "tokens=1,* delims=:" %%A in ('findstr /i "\"version\"" "%VERJSON%"') do set "VER=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /i "\"build\"" "%VERJSON%"') do set "BUILD=%%B"

REM Clean extracted values (remove commas, quotes, spaces)
set "VER=%VER:,=%"
set "VER=%VER:"=%"
set "VER=%VER: =%"
set "BUILD=%BUILD:,=%"
set "BUILD=%BUILD:"=%"
set "BUILD=%BUILD: =%"

>>"%LOG%" echo RAW_VER=%VER%
>>"%LOG%" echo RAW_BUILD=%BUILD%

if "%VER%"=="" (
  >>"%LOG%" echo ERROR: Could not parse version from version.json
  goto :fail
)

if "%BUILD%"=="" (
  >>"%LOG%" echo ERROR: Could not parse build from version.json
  goto :fail
)

set "ZIPNAME=%PROJ%-v%VER% v%BUILD%.zip"
set "ZIPPATH=%BASE%\%ZIPNAME%"
>>"%LOG%" echo ZIPPATH=%ZIPPATH%

if exist "%ZIPPATH%" del /f /q "%ZIPPATH%" >>"%LOG%" 2>&1

REM ── STAGING COPY ───────────────────────────────────────────
set "STAGE=%BASE%\_zip_stage_rpi"
>>"%LOG%" echo STAGE=%STAGE%

if exist "%STAGE%" rmdir /s /q "%STAGE%" >>"%LOG%" 2>&1
mkdir "%STAGE%\%PROJ%" >>"%LOG%" 2>&1

REM Copy project to stage, excluding dirs by name
robocopy "%SRC%" "%STAGE%\%PROJ%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS ^
  /XD ".venv" "__pycache__" ".git" "node_modules" >>"%LOG%" 2>&1

set "RC=%ERRORLEVEL%"
>>"%LOG%" echo ROBOCOPY_EXIT_CODE=%RC%
if %RC% GEQ 8 (
  >>"%LOG%" echo ERROR: robocopy failed
  goto :fail_cleanup
)

REM Remove any stray compiled files
del /s /q "%STAGE%\%PROJ%\*.pyc" >>"%LOG%" 2>&1

REM ── ZIP FROM STAGE ─────────────────────────────────────────
>>"%LOG%" echo Running 7z (from stage)...
pushd "%STAGE%" >nul

"%SEVENZIP%" a -tzip "%ZIPPATH%" "%PROJ%" -r >>"%LOG%" 2>&1
set "ZERR=%ERRORLEVEL%"

popd >nul
>>"%LOG%" echo 7Z_EXIT_CODE=%ZERR%

if not "%ZERR%"=="0" (
  >>"%LOG%" echo ERROR: 7-Zip failed
  goto :fail_cleanup
)

REM Verify exclusions (log only)
"%SEVENZIP%" l "%ZIPPATH%" | findstr /i "\.venv __pycache__" >nul 2>&1
if "%ERRORLEVEL%"=="0" (
  >>"%LOG%" echo WARNING: .venv or __pycache__ detected in zip
) else (
  >>"%LOG%" echo Verified: no .venv/__pycache__ paths detected
)

REM ── Cleanup ────────────────────────────────────────────────
rmdir /s /q "%STAGE%" >>"%LOG%" 2>&1

if not exist "%ZIPPATH%" (
  >>"%LOG%" echo ERROR: Zip not created
  goto :fail
)

>>"%LOG%" echo SUCCESS
echo DONE: "%ZIPPATH%"
popd >nul
exit /b 0

:fail_cleanup
if exist "%STAGE%" rmdir /s /q "%STAGE%" >>"%LOG%" 2>&1

:fail
echo FAILED. See log: "%LOG%"
popd >nul
exit /b 1
