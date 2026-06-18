@echo off
REM ============================================================
REM  KickOff - one-click Windows build + installer
REM  Double-click this file (or run it from a terminal) to:
REM    1) build the release app   (flutter build windows --release)
REM    2) compile the installer   (Inno Setup -> installer\Output)
REM ============================================================
setlocal enabledelayedexpansion
cd /d "%~dp0"

echo.
echo ===[ 1/2 ] Building release app...
call flutter build windows --release
if errorlevel 1 (
    echo.
    echo *** Flutter build FAILED. Fix the errors above and run again. ***
    pause
    exit /b 1
)

echo.
echo ===[ 2/2 ] Compiling installer...

REM --- Find the Inno Setup compiler (ISCC.exe) ---
set "ISCC="
for %%P in (
    "%LOCALAPPDATA%\Programs\Inno Setup 6\ISCC.exe"
    "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
    "%ProgramFiles%\Inno Setup 6\ISCC.exe"
) do (
    if exist "%%~P" set "ISCC=%%~P"
)

if not defined ISCC (
    echo.
    echo *** Inno Setup not found. Install it once with: ***
    echo     winget install --id JRSoftware.InnoSetup -e
    pause
    exit /b 1
)

"%ISCC%" "installer\kickoff.iss"
if errorlevel 1 (
    echo.
    echo *** Installer compile FAILED. See the errors above. ***
    pause
    exit /b 1
)

echo.
echo ============================================================
echo  DONE. Installer is in:  installer\Output\
echo ============================================================
REM Open the output folder in Explorer.
start "" "%~dp0installer\Output"
pause
