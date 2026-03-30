@echo off
REM ============================================================================
REM  PDF Editor Suite - One-Click Installer
REM  by sariamubeen
REM ============================================================================
REM  Just double-click this file. It handles everything:
REM    - Checks for admin rights (re-launches elevated if needed)
REM    - Asks for your server IP
REM    - Installs and registers the PDF handler
REM    - Validates the setup
REM ============================================================================

:: Check for admin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

title PDF Editor Suite - Installer

echo.
echo   +==========================================================+
echo   ^|  PDF Editor Suite - One-Click Installer                   ^|
echo   ^|                                          by sariamubeen  ^|
echo   +==========================================================+
echo.

:: Get server URL from user
set /p SERVER_URL="  Enter your server URL (e.g. http://192.168.1.50:8080): "

if "%SERVER_URL%"=="" (
    echo.
    echo   ERROR: No URL entered. Exiting.
    pause
    exit /b 1
)

echo.
echo   Server: %SERVER_URL%
echo   Installing...
echo.

:: Set paths
set "INSTALL_DIR=%ProgramFiles%\PDFEditorSuite"
set "SCRIPT_DIR=%~dp0"
set "CLIENT_DIR=%SCRIPT_DIR%client"
set "PROGID=PDFEditorSuite.PDF"
set "DISPLAY_NAME=PDF Editor Suite (Browser)"

:: Check client folder exists
if not exist "%CLIENT_DIR%\Open-PDFInBrowser.ps1" (
    echo   ERROR: client folder not found at %CLIENT_DIR%
    echo   Make sure INSTALL.bat is in the pdf-editor-suite root folder.
    pause
    exit /b 1
)

:: Step 1: Create install directory
echo   [1/5] Creating install directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo         %INSTALL_DIR%

:: Step 2: Generate config.ps1
echo   [2/5] Generating configuration...
(
echo # PDF Editor Suite - Client Configuration [auto-generated]
echo.
echo $PDFEditorURL = "%SERVER_URL%"
echo.
echo $RequireLogin = $false
echo.
echo $StirlingUsername = "admin"
echo $StirlingPassword = "ChangeMeOnFirstLogin!"
echo.
echo $InstallDir = "$env:ProgramFiles\PDFEditorSuite"
echo.
echo $ProgId = "%PROGID%"
echo.
echo $DisplayName = "%DISPLAY_NAME%"
) > "%INSTALL_DIR%\config.ps1"
echo         config.ps1 generated

:: Step 3: Copy scripts
echo   [3/5] Installing scripts...
copy /y "%CLIENT_DIR%\Open-PDFInBrowser.ps1" "%INSTALL_DIR%\" >nul
echo         Open-PDFInBrowser.ps1 installed
copy /y "%CLIENT_DIR%\open-pdf.bat" "%INSTALL_DIR%\" >nul
echo         open-pdf.bat installed

:: Step 4: Register file association
echo   [4/5] Registering .pdf file handler...

set "BATCH_PATH=%INSTALL_DIR%\open-pdf.bat"

:: Create ProgId
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /ve /d "%DISPLAY_NAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /v "FriendlyTypeName" /d "%DISPLAY_NAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\shell\open\command" /ve /d "\"%BATCH_PATH%\" \"%%1\"" /f >nul 2>&1

:: Back up current handler
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CURRENT_HANDLER=%%b"
if defined CURRENT_HANDLER (
    if not "%CURRENT_HANDLER%"=="%PROGID%" (
        reg add "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /d "%CURRENT_HANDLER%" /f >nul 2>&1
        echo         Backed up previous handler: %CURRENT_HANDLER%
    )
)

:: Set .pdf association
reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PROGID%" /f >nul 2>&1
ftype %PROGID%="%BATCH_PATH%" "%%1" >nul 2>&1
assoc .pdf=%PROGID% >nul 2>&1
echo         .pdf handler registered

:: Step 5: Validate
echo   [5/5] Validating...

set "ALL_GOOD=1"

if exist "%INSTALL_DIR%\config.ps1" (
    echo         [OK] config.ps1
) else (
    echo         [!!] config.ps1 MISSING
    set "ALL_GOOD=0"
)

if exist "%INSTALL_DIR%\Open-PDFInBrowser.ps1" (
    echo         [OK] Open-PDFInBrowser.ps1
) else (
    echo         [!!] Open-PDFInBrowser.ps1 MISSING
    set "ALL_GOOD=0"
)

if exist "%INSTALL_DIR%\open-pdf.bat" (
    echo         [OK] open-pdf.bat
) else (
    echo         [!!] open-pdf.bat MISSING
    set "ALL_GOOD=0"
)

reg query "HKLM\SOFTWARE\Classes\%PROGID%" >nul 2>&1
if %errorlevel% equ 0 (
    echo         [OK] Registry handler
) else (
    echo         [!!] Registry handler MISSING
    set "ALL_GOOD=0"
)

echo.

if "%ALL_GOOD%"=="1" (
    echo   +==========================================================+
    echo   ^|  Setup Complete!                            sariamubeen  ^|
    echo   ^|                                                          ^|
    echo   ^|  Double-click any .pdf to open it in the browser editor. ^|
    echo   ^|                                                          ^|
    echo   ^|  Server: %SERVER_URL%
    echo   ^|  Auth  : No login required                               ^|
    echo   ^|                                                          ^|
    echo   ^|  To uninstall: run UNINSTALL.bat                         ^|
    echo   +==========================================================+
) else (
    echo   Setup finished with errors - review output above.
)

echo.
echo   NOTE: On Windows 10/11 you may also need to set the default app:
echo     Settings ^> Apps ^> Default apps ^> search '.pdf'
echo     Select '%DISPLAY_NAME%'
echo.
pause
