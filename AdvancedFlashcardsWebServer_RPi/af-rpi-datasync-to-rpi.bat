@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM af-rpi-datasync-to-rpi.bat — Push WebServer data to RPi
REM Project: AdvancedFlashcardsWebServer_RPi
REM ============================================================
REM Copies your local KenpoFlashcardsWebServer\data\ to the RPi.
REM
REM Usage:
REM   af-rpi-datasync-to-rpi.bat <rpi-ip> [rpi-user]
REM
REM Example:
REM   af-rpi-datasync-to-rpi.bat 192.168.1.50
REM   af-rpi-datasync-to-rpi.bat 192.168.1.50 pi
REM ============================================================

set "RPI_IP=%~1"
set "RPI_USER=%~2"
if "%RPI_USER%"=="" set "RPI_USER=pi"

if "%RPI_IP%"=="" (
    echo.
    echo  Usage: af-rpi-datasync-to-rpi.bat ^<rpi-ip^> [rpi-user]
    echo.
    echo  Example: af-rpi-datasync-to-rpi.bat 192.168.1.50
    echo           af-rpi-datasync-to-rpi.bat 192.168.1.50 pi
    echo.
    pause
    exit /b 1
)

REM ── Find data directory ────────────────────────────────────
set "SCRIPT_DIR=%~dp0"

if exist "%SCRIPT_DIR%data\" (
    set "LOCAL_DATA=%SCRIPT_DIR%data"
    goto :found
)

set "MONO_DATA=%USERPROFILE%\Documents\GitHub\sidscri-apps\KenpoFlashcardsWebServer\data"
if exist "%MONO_DATA%\" (
    set "LOCAL_DATA=%MONO_DATA%"
    goto :found
)

echo [ERROR] Could not find KenpoFlashcardsWebServer\data\ directory
echo.
echo  Looked in:
echo    %SCRIPT_DIR%data\
echo    %MONO_DATA%\
echo.
echo  Place this script in the KenpoFlashcardsWebServer folder
echo  or in the sidscri-apps root.
pause
exit /b 1

:found
echo.
echo  ==================================================
echo   Advanced Flashcards — Push Data to RPi
echo  ==================================================
echo.
echo  Source (Windows): %LOCAL_DATA%
echo  Target (RPi):     %RPI_USER%@%RPI_IP%:/opt/advanced-flashcards/data/
echo.

set "FILE_COUNT=0"
for /r "%LOCAL_DATA%" %%f in (*.json *.txt *.enc) do set /a FILE_COUNT+=1
echo  Files to sync: %FILE_COUNT%
echo.

set /p CONFIRM="  Continue? (y/N): "
if /i not "%CONFIRM%"=="y" (
    echo  Cancelled.
    pause
    exit /b 0
)

echo.
echo [INFO] Stopping RPi service before sync...
ssh %RPI_USER%@%RPI_IP% "sudo systemctl stop advanced-flashcards 2>/dev/null; echo stopped"

echo [INFO] Syncing data to RPi...
scp -r "%LOCAL_DATA%\*" %RPI_USER%@%RPI_IP%:/opt/advanced-flashcards/data/

if errorlevel 1 (
    echo.
    echo [ERROR] scp failed! Check your SSH connection.
    echo  - Is SSH enabled on the RPi? (sudo systemctl enable ssh)
    echo  - Can you connect? ssh %RPI_USER%@%RPI_IP%
    echo.
    echo [INFO] Restarting RPi service...
    ssh %RPI_USER%@%RPI_IP% "sudo systemctl start advanced-flashcards"
    pause
    exit /b 1
)

echo.
echo [INFO] Restarting RPi service...
ssh %RPI_USER%@%RPI_IP% "sudo systemctl start advanced-flashcards"

echo.
echo  ==================================================
echo   Done! Data synced to RPi.
echo  ==================================================
echo.
echo   RPi server: http://%RPI_IP%:8009
echo.
pause
