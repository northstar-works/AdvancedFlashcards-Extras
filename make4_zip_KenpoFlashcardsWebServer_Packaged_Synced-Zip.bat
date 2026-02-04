@echo off
setlocal EnableExtensions EnableDelayedExpansion

REM ============================================================
REM make3_zip_KenpoFlashcardsWebServer_Packaged_Synced-Zip.bat
REM Put this BAT in: ...\sidscri-apps\
REM Creates ZIP in the SAME folder as this BAT:
REM   KenpoFlashcardsWebServer_Packaged-v<version> v<build>[-ws<wsver>_b<wsbuild>].zip
REM ZIP contents root folder:
REM   KenpoFlashcardsWebServer_Packaged\...
REM Reads:
REM   .\KenpoFlashcardsWebServer_Packaged_Synced\version.json
REM Uses version.json fields (no Sync log scanning):
REM   "webserver_version": "8.5.1"
REM   "webserver_build": 54
REM Excludes (recursively, guaranteed):
REM   .venv, __pycache__, build, dist, packaging\output, build_data, packaging\build_data, *.pyc
REM Writes log:
REM   logs\KenpoFlashcardsWebServerPackaged.log
REM ============================================================

REM Always run from the BAT's folder
set "BASE=%~dp0"
if "%BASE:~-1%"=="\" set "BASE=%BASE:~0,-1%"
pushd "%BASE%" >nul

set "LOG=%BASE%\logs\KenpoFlashcardsWebServerPackaged.log"
if not exist "%BASE%\logs" mkdir "%BASE%\logs" >nul 2>&1
> "%LOG%" echo START %DATE% %TIME%
>>"%LOG%" echo BASE=%BASE%

REM Source folder (synced project)
set "PROJ_SRC=KenpoFlashcardsWebServer_Packaged_Synced"
set "SRC=%BASE%\%PROJ_SRC%"
set "VERJSON=%SRC%\version.json"

REM Output zip name + folder name inside zip (NO _Synced)
set "PROJ_ZIP=KenpoFlashcardsWebServer_Packaged"

>>"%LOG%" echo SRC=%SRC%
>>"%LOG%" echo VERJSON=%VERJSON%
>>"%LOG%" echo PROJ_ZIP=%PROJ_ZIP%

if not exist "%SRC%\" (
  >>"%LOG%" echo ERROR: Project folder not found
  goto :fail
)

if not exist "%VERJSON%" (
  >>"%LOG%" echo ERROR: version.json not found
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

REM Parse fields from JSON using findstr (no PowerShell required)
set "VER="
set "BUILD="
set "WSVER="
set "WSBUILD="

for /f "tokens=1,* delims=:" %%A in ('findstr /i "\"version\"" "%VERJSON%"') do set "VER=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /i "\"build\"" "%VERJSON%"') do set "BUILD=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /i "\"webserver_version\"" "%VERJSON%"') do set "WSVER=%%B"
for /f "tokens=1,* delims=:" %%A in ('findstr /i "\"webserver_build\"" "%VERJSON%"') do set "WSBUILD=%%B"

REM Clean extracted values
set "VER=%VER:,=%"
set "VER=%VER:"=%"
set "VER=%VER: =%"

set "BUILD=%BUILD:,=%"
set "BUILD=%BUILD:"=%"
set "BUILD=%BUILD: =%"

set "WSVER=%WSVER:,=%"
set "WSVER=%WSVER:"=%"
set "WSVER=%WSVER: =%"

set "WSBUILD=%WSBUILD:,=%"
set "WSBUILD=%WSBUILD:"=%"
set "WSBUILD=%WSBUILD: =%"

>>"%LOG%" echo VER=%VER%
>>"%LOG%" echo BUILD=%BUILD%
>>"%LOG%" echo WSVER=%WSVER%
>>"%LOG%" echo WSBUILD=%WSBUILD%

if "%VER%"=="" (
  >>"%LOG%" echo ERROR: Could not parse version from version.json
  goto :fail
)

if "%BUILD%"=="" (
  >>"%LOG%" echo ERROR: Could not parse build from version.json
  goto :fail
)

REM Optional ws suffix: -ws8.5.1_b54
set "WSSUFFIX="
if not "%WSVER%"=="" if not "%WSBUILD%"=="" (
  set "WSSUFFIX=-ws%WSVER%_b%WSBUILD%"
)

>>"%LOG%" echo WSSUFFIX=%WSSUFFIX%

set "ZIPNAME=%PROJ_ZIP%-v%VER% v%BUILD%%WSSUFFIX%.zip"
set "ZIPPATH=%BASE%\%ZIPNAME%"
>>"%LOG%" echo ZIPPATH=%ZIPPATH%

if exist "%ZIPPATH%" del /f /q "%ZIPPATH%" >>"%LOG%" 2>&1

REM ---------- STAGING COPY ----------
set "STAGE=%BASE%\_zip_stage"
>>"%LOG%" echo STAGE=%STAGE%

if exist "%STAGE%" rmdir /s /q "%STAGE%" >>"%LOG%" 2>&1
mkdir "%STAGE%\%PROJ_ZIP%" >>"%LOG%" 2>&1

REM Copy project to stage while excluding directories by NAME (recursive)
REM robocopy exit codes 0-7 = OK, >=8 = failure
robocopy "%SRC%" "%STAGE%\%PROJ_ZIP%" /E /R:1 /W:1 /NFL /NDL /NP /NJH /NJS ^
  /XD ".venv" "__pycache__" "build" "dist" "build_data" "packaging\output" "packaging\build_data" >>"%LOG%" 2>&1

set "RC=%ERRORLEVEL%"
>>"%LOG%" echo ROBOCOPY_EXIT_CODE=%RC%
if %RC% GEQ 8 (
  >>"%LOG%" echo ERROR: robocopy failed
  goto :fail_cleanup
)

REM Remove any stray .pyc files (just in case)
del /s /q "%STAGE%\%PROJ_ZIP%\*.pyc" >>"%LOG%" 2>&1

REM ---------- ZIP FROM STAGE ----------
>>"%LOG%" echo Running 7z (from stage)...
pushd "%STAGE%" >nul

"%SEVENZIP%" a -tzip "%ZIPPATH%" "%PROJ_ZIP%" -r >>"%LOG%" 2>&1
set "ZERR=%ERRORLEVEL%"
popd >nul

>>"%LOG%" echo 7Z_EXIT_CODE=%ZERR%

if not "%ZERR%"=="0" (
  >>"%LOG%" echo ERROR: 7-Zip failed
  goto :fail_cleanup
)

REM Cleanup stage
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
REM Try to cleanup stage folder on failure
if exist "%STAGE%" rmdir /s /q "%STAGE%" >>"%LOG%" 2>&1

:fail
echo FAILED. See log: "%LOG%"
popd >nul
exit /b 1
