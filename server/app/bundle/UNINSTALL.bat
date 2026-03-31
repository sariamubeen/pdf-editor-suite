@echo off
setlocal

:: ============================================================================
::  SIERA PDF - Uninstaller
:: ============================================================================

cd /d "%~dp0"

:: Admin check
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
echo   ^|  SIERA PDF - Uninstaller                                  ^|
echo   +==========================================================+
echo.

set "INSTDIR=%ProgramFiles%\SieraPDF"
set "PROGID=SieraPDF.PDF"

:: Step 1: Restore previous PDF handler
echo   [1/5] Restoring previous PDF handler...
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

:: Step 2: Remove registry
echo   [2/5] Removing file handler...
reg delete "HKLM\SOFTWARE\Classes\%PROGID%" /f >nul 2>&1
ftype %PROGID%= >nul 2>&1
echo         OK

:: Step 3: Remove Windows app registration
echo   [3/5] Removing app registration...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\SieraPDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /f >nul 2>&1
echo         OK

:: Step 4: Remove files
echo   [4/5] Removing installed files...
if exist "%INSTDIR%" (
    rmdir /s /q "%INSTDIR%"
    echo         OK: Removed %INSTDIR%
) else (
    echo         Already removed
)

:: Step 5: Verify
echo   [5/5] Verifying...
reg query "HKLM\SOFTWARE\Classes\%PROGID%" >nul 2>&1
if %errorlevel% neq 0 (echo         [OK] Registry clean) else (echo         [!!] Registry entries remain)
if not exist "%INSTDIR%" (echo         [OK] Files removed) else (echo         [!!] Install directory remains)

echo.
echo   +==========================================================+
echo   ^|  SIERA PDF has been uninstalled.                          ^|
echo   +==========================================================+
echo.
pause
endlocal
