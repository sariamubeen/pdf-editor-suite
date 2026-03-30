@echo off
setlocal

:: ============================================================================
::  PDF Editor Suite - Uninstaller by sariamubeen
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

title PDF Editor Suite - Uninstaller
echo.
echo   +==========================================================+
echo   ^|  PDF Editor Suite - Uninstaller             sariamubeen  ^|
echo   +==========================================================+
echo.

set "INSTDIR=%ProgramFiles%\PDFEditorSuite"
set "PROGID=PDFEditorSuite.PDF"

:: ── Step 1: Restore previous PDF handler ────────────────────────────────────
echo   [1/5] Restoring previous PDF handler...
set "PREV="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" 2^>nul ^| find "REG_SZ"') do set "PREV=%%b"
if defined PREV (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PREV%" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /f >nul 2>&1
    echo         OK: Restored %PREV%
) else (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "" /f >nul 2>&1
    echo         OK: Cleared .pdf association
)

:: ── Step 2: Remove classic registry ─────────────────────────────────────────
echo   [2/5] Removing file handler registry...
reg delete "HKLM\SOFTWARE\Classes\%PROGID%" /f >nul 2>&1
ftype %PROGID%= >nul 2>&1
echo         OK: ProgId and ftype removed

:: ── Step 3: Remove Windows 10/11 app registration ──────────────────────────
echo   [3/5] Removing Windows app registration...
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\PDFEditorSuite" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /f >nul 2>&1
reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /f >nul 2>&1
echo         OK: App registration removed

:: ── Step 4: Remove install directory ────────────────────────────────────────
echo   [4/5] Removing installed files...
if exist "%INSTDIR%" (
    rmdir /s /q "%INSTDIR%"
    echo         OK: Removed %INSTDIR%
) else (
    echo         Already removed
)

:: ── Step 5: Verify ──────────────────────────────────────────────────────────
echo   [5/5] Verifying...

reg query "HKLM\SOFTWARE\Classes\%PROGID%" >nul 2>&1
if %errorlevel% neq 0 (echo         [OK] Registry clean) else (echo         [!!] Registry entries remain)

if not exist "%INSTDIR%" (echo         [OK] Files removed) else (echo         [!!] Install directory remains)

echo.
echo   +==========================================================+
echo   ^|  Uninstall Complete                         sariamubeen  ^|
echo   ^|                                                          ^|
echo   ^|  PDF file association has been reverted.                  ^|
echo   ^|  You may need to set your preferred PDF app in:          ^|
echo   ^|  Settings ^> Apps ^> Default apps ^> .pdf                   ^|
echo   +==========================================================+
echo.
pause
endlocal
