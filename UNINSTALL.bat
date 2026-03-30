@echo off
REM ============================================================================
REM  PDF Editor Suite - Uninstaller (self-contained)
REM  by sariamubeen
REM ============================================================================

:: Check for admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

title PDF Editor Suite - Uninstaller

echo.
echo   PDF Editor Suite - Uninstaller
echo.

set "INSTALL_DIR=%ProgramFiles%\PDFEditorSuite"
set "PROGID=PDFEditorSuite.PDF"

:: Restore previous handler
set "PREV_HANDLER="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" 2^>nul ^| find "REG_SZ"') do set "PREV_HANDLER=%%b"
if defined PREV_HANDLER (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PREV_HANDLER%" /f >nul 2>&1
    reg delete "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /f >nul 2>&1
    echo   [OK] Restored previous handler: %PREV_HANDLER%
) else (
    reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "" /f >nul 2>&1
    echo   [OK] Cleared .pdf association
)

:: Remove ProgId
reg delete "HKLM\SOFTWARE\Classes\%PROGID%" /f >nul 2>&1
echo   [OK] Removed file handler

:: Remove ftype
ftype %PROGID%= >nul 2>&1

:: Remove install directory
if exist "%INSTALL_DIR%" (
    rmdir /s /q "%INSTALL_DIR%"
    echo   [OK] Removed %INSTALL_DIR%
)

echo.
echo   Uninstall complete. PDF association has been reverted.
echo.
pause
