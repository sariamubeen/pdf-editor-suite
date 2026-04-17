@echo off
setlocal

:: ============================================================================
::  SIERA PDF - Uninstaller
:: ============================================================================

cd /d "%~dp0"
net session >nul 2>&1
if %errorlevel% neq 0 (
    powershell -NoProfile -WindowStyle Hidden -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

title SIERA PDF - Uninstaller
echo.
echo   Uninstalling SIERA PDF...
echo.

set "INSTDIR=%ProgramFiles%\SieraPDF"
set "PROGID=SieraPDF.PDF"

:: Restore previous handler if backed up
set "PREV="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" 2^>nul ^| find "REG_SZ"') do set "PREV=%%b"
if defined PREV (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PREV%" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" /f >nul 2>&1
) else (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "" /f >nul 2>&1
)

:: Remove all registry entries
reg delete "HKLM\SOFTWARE\Classes\%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\SieraPDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
ftype %PROGID%= >nul 2>&1

:: Remove install directory
if exist "%INSTDIR%" rmdir /s /q "%INSTDIR%"

:: Notify shell (no Explorer restart)
rundll32.exe shell32.dll,SHChangeNotify 0x08000000,0,0,0 >nul 2>&1
ie4uinit.exe -show >nul 2>&1

echo   Done. SIERA PDF has been uninstalled.
echo.
timeout /t 2 >nul
exit /b 0
