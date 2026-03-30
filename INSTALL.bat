@echo off
REM ============================================================================
REM  PDF Editor Suite - One-Click Installer (fully self-contained)
REM  by sariamubeen
REM ============================================================================
REM  Double-click this file. Nothing else needed.
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
set "PROGID=PDFEditorSuite.PDF"
set "DISPLAY_NAME=PDF Editor Suite (Browser)"

:: ============================================================================
:: Step 1: Create install directory
:: ============================================================================
echo   [1/6] Creating install directory...
if not exist "%INSTALL_DIR%" mkdir "%INSTALL_DIR%"
echo         %INSTALL_DIR%

:: ============================================================================
:: Step 2: Generate all required files directly (no dependencies)
:: ============================================================================
echo   [2/6] Creating scripts...

:: --- open-pdf.bat (the file association target) ---
(
echo @echo off
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%~dp0Open-PDFInBrowser.ps1" "%%~1"
) > "%INSTALL_DIR%\open-pdf.bat"
echo         open-pdf.bat created

:: --- config.ps1 ---
(
echo $PDFEditorURL = "%SERVER_URL%"
echo $RequireLogin = $false
echo $StirlingUsername = "admin"
echo $StirlingPassword = ""
echo $InstallDir = "$env:ProgramFiles\PDFEditorSuite"
echo $ProgId = "%PROGID%"
echo $DisplayName = "%DISPLAY_NAME%"
) > "%INSTALL_DIR%\config.ps1"
echo         config.ps1 created

:: --- Open-PDFInBrowser.ps1 (copies PDF to shared folder + opens editor) ---
:: Copies the PDF to a server-accessible path and opens Stirling-PDF multi-tool
> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo param([Parameter(Mandatory=$true,Position=0)][string]$PdfPath)
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo $ErrorActionPreference = "Stop"
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo . (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "config.ps1")
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo if (-not (Test-Path -LiteralPath $PdfPath)) { exit 1 }
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo $PdfPath = (Resolve-Path -LiteralPath $PdfPath).Path
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo $FileName = [System.IO.Path]::GetFileName($PdfPath)
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo try { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::SetDataObject((New-Object System.Windows.Forms.DataObject("FileDrop", [string[]]@($PdfPath))), $true) } catch {}
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo Start-Process "$PDFEditorURL/multi-tool"
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo Start-Sleep -Milliseconds 500
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo try {
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n = New-Object System.Windows.Forms.NotifyIcon
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n.Icon = [System.Drawing.SystemIcons]::Information
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n.Visible = $true
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n.BalloonTipTitle = "PDF Editor Suite"
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n.BalloonTipText = "$FileName copied to clipboard. Drop or browse to upload in the editor."
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n.ShowBalloonTip(5000)
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   Start-Sleep -Seconds 6
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo   $n.Dispose()
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo } catch {}
>> "%INSTALL_DIR%\Open-PDFInBrowser.ps1" echo exit 0
echo         Open-PDFInBrowser.ps1 created

:: ============================================================================
:: Step 3: Register file association (classic method)
:: ============================================================================
echo   [3/6] Registering .pdf file handler...

set "BATCH_PATH=%INSTALL_DIR%\open-pdf.bat"

:: Create ProgId
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /ve /d "%DISPLAY_NAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /v "FriendlyTypeName" /d "%DISPLAY_NAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\shell\open\command" /ve /d "\"%BATCH_PATH%\" \"%%1\"" /f >nul 2>&1

:: Back up current handler
set "CURRENT_HANDLER="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CURRENT_HANDLER=%%b"
if defined CURRENT_HANDLER (
    if not "%CURRENT_HANDLER%"=="%PROGID%" (
        reg add "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /d "%CURRENT_HANDLER%" /f >nul 2>&1
        echo         Backed up previous handler: %CURRENT_HANDLER%
    )
)

:: Set .pdf association (classic)
reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PROGID%" /f >nul 2>&1
ftype %PROGID%="%BATCH_PATH%" "%%1" >nul 2>&1
assoc .pdf=%PROGID% >nul 2>&1
echo         .pdf handler registered (classic)

:: ============================================================================
:: Step 4: Force Windows 10/11 default app association
:: ============================================================================
echo   [4/6] Setting as Windows default PDF app...

:: Register in OpenWithProgids so it appears in "Open with" list
reg add "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1

:: Register application capabilities
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities" /v "ApplicationName" /d "%DISPLAY_NAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities" /v "ApplicationDescription" /d "Opens PDFs in browser-based editor" /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities\FileAssociations" /v ".pdf" /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /d "SOFTWARE\PDFEditorSuite\Capabilities" /f >nul 2>&1

:: Remove the current user's UserChoice for .pdf so Windows re-evaluates
:: (This forces Windows to use our ProgId since we set it as default)
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1

:: Also set the per-user OpenWithList to prefer our handler
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1

:: Generate DefaultAssociations.xml for GPO deployment
(
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<DefaultAssociations^>
echo   ^<Association Identifier=".pdf" ProgId="%PROGID%" ApplicationName="%DISPLAY_NAME%" /^>
echo ^</DefaultAssociations^>
) > "%INSTALL_DIR%\DefaultAssociations.xml"

:: Apply DefaultAssociations via local group policy (works on Pro/Enterprise)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /d "%INSTALL_DIR%\DefaultAssociations.xml" /f >nul 2>&1

echo         Default app association set

:: Notify shell of changes
powershell -NoProfile -Command "[System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.Runtime.InteropServices.Marshal]::GetActiveObject('Shell.Application')) 2>$null" >nul 2>&1

:: ============================================================================
:: Step 5: Create uninstaller in install directory
:: ============================================================================
echo   [5/6] Creating uninstaller...

> "%INSTALL_DIR%\Uninstall.bat" echo @echo off
>> "%INSTALL_DIR%\Uninstall.bat" echo net session ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo if %%errorlevel%% neq 0 ( powershell -Command "Start-Process '%%~f0' -Verb RunAs" ^& exit /b )
>> "%INSTALL_DIR%\Uninstall.bat" echo echo Uninstalling PDF Editor Suite...
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "PDFEditorSuite.PDF" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "PDFEditorSuite.PDF" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKLM\SOFTWARE\PDFEditorSuite" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo set "PREV="
>> "%INSTALL_DIR%\Uninstall.bat" echo for /f "tokens=2*" %%%%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" 2^^^>nul ^^^| find "REG_SZ"') do set "PREV=%%%%b"
>> "%INSTALL_DIR%\Uninstall.bat" echo if defined PREV ( reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%%PREV%%" /f ^>nul 2^>^&1 ^& reg delete "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /f ^>nul 2^>^&1 )
>> "%INSTALL_DIR%\Uninstall.bat" echo reg delete "HKLM\SOFTWARE\Classes\%PROGID%" /f ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo ftype %PROGID%= ^>nul 2^>^&1
>> "%INSTALL_DIR%\Uninstall.bat" echo echo   [OK] File association removed
>> "%INSTALL_DIR%\Uninstall.bat" echo rmdir /s /q "%INSTALL_DIR%" 2^>nul
>> "%INSTALL_DIR%\Uninstall.bat" echo echo   [OK] Uninstall complete
>> "%INSTALL_DIR%\Uninstall.bat" echo pause
echo         Uninstaller created

:: ============================================================================
:: Step 6: Validate
:: ============================================================================
echo   [6/6] Validating...

set "ALL_GOOD=1"

if exist "%INSTALL_DIR%\config.ps1" (echo         [OK] config.ps1) else (echo         [!!] config.ps1 MISSING & set "ALL_GOOD=0")
if exist "%INSTALL_DIR%\Open-PDFInBrowser.ps1" (echo         [OK] Open-PDFInBrowser.ps1) else (echo         [!!] Open-PDFInBrowser.ps1 MISSING & set "ALL_GOOD=0")
if exist "%INSTALL_DIR%\open-pdf.bat" (echo         [OK] open-pdf.bat) else (echo         [!!] open-pdf.bat MISSING & set "ALL_GOOD=0")

reg query "HKLM\SOFTWARE\Classes\%PROGID%" >nul 2>&1
if %errorlevel% equ 0 (echo         [OK] Registry handler) else (echo         [!!] Registry MISSING & set "ALL_GOOD=0")

reg query "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" >nul 2>&1
if %errorlevel% equ 0 (echo         [OK] Registered as Windows app) else (echo         [!!] App registration MISSING & set "ALL_GOOD=0")

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
    echo   ^|  Uninstall: %INSTALL_DIR%\Uninstall.bat
    echo   +==========================================================+
    echo.
    echo   If .pdf still opens in another app, we will open Settings
    echo   for you now. Select 'PDF Editor Suite (Browser)' for .pdf
    echo.
    echo   Opening Windows Default Apps settings...
    start ms-settings:defaultapps
) else (
    echo   Setup finished with errors - review output above.
)

echo.
pause
