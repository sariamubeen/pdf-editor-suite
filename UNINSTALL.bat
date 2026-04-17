@echo off
setlocal

:: ============================================================================
::  SIERA PDF - Uninstaller
:: ============================================================================

cd /d "%~dp0"

net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

cd /d "%~dp0"

title SIERA PDF - Uninstaller
echo.
echo   +==========================================================+
echo   ^|  SIERA PDF - Uninstaller                                 ^|
echo   +==========================================================+
echo.

set "INSTDIR=%ProgramFiles%\SieraPDF"
set "PROGID=SieraPDF.PDF"

echo   [1/4] Restoring previous PDF handler...
set "PREV="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" 2^>nul ^| find "REG_SZ"') do set "PREV=%%b"
if defined PREV (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PREV%" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" /f >nul 2>&1
    echo         OK: Restored %PREV%
) else (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "" /f >nul 2>&1
    echo         OK: Cleared .pdf association
)

echo   [2/4] Removing registry entries...
reg delete "HKLM\SOFTWARE\Classes\%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\Applications\open-pdf.bat" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\SieraPDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
ftype %PROGID%= >nul 2>&1
echo         OK: Registry cleaned

echo   [3/4] Removing installed files...
if exist "%INSTDIR%" (
    rmdir /s /q "%INSTDIR%"
    echo         OK: Removed %INSTDIR%
) else (
    echo         Already removed
)

echo   [4/4] Refreshing icon cache...
ie4uinit.exe -show >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
del /f /s /q "%LocalAppData%\IconCache.db" >nul 2>&1
del /f /s /q "%LocalAppData%\Microsoft\Windows\Explorer\iconcache*" >nul 2>&1
start explorer.exe
timeout /t 2 >nul

echo.
echo   +==========================================================+
echo   ^|  SIERA PDF has been uninstalled.                         ^|
echo   +==========================================================+
echo.
pause
endlocal
