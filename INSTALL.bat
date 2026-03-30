@echo off
setlocal EnableDelayedExpansion
REM ============================================================================
REM  PDF Editor Suite - One-Click Installer (fully self-contained)
REM  by sariamubeen
REM ============================================================================

:: Save script path before anything changes it
set "SCRIPTPATH=%~f0"
set "SCRIPTDIR=%~dp0"

:: Remove trailing backslash from SCRIPTDIR (prevents quote-escaping bugs)
if "%SCRIPTDIR:~-1%"=="\" set "SCRIPTDIR=%SCRIPTDIR:~0,-1%"

:: Change to script directory
cd /d "%SCRIPTDIR%"

:: Check for admin - if not admin, re-launch elevated
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    echo Set objShell = CreateObject("Shell.Application") > "%temp%\pdfes_elevate.vbs"
    echo objShell.ShellExecute "cmd.exe", "/k cd /d ""%SCRIPTDIR%"" ^& ""%SCRIPTPATH%""", "", "runas", 1 >> "%temp%\pdfes_elevate.vbs"
    cscript //nologo "%temp%\pdfes_elevate.vbs"
    del /q "%temp%\pdfes_elevate.vbs" >nul 2>&1
    exit /b
)

title PDF Editor Suite - Installer
cd /d "%SCRIPTDIR%"

echo.
echo   +==========================================================+
echo   ^|  PDF Editor Suite - One-Click Installer                   ^|
echo   ^|                                          by sariamubeen  ^|
echo   +==========================================================+
echo.

:: Get server URL
set /p SERVER_URL="  Enter your server URL (e.g. http://192.168.1.50:8080): "
if "!SERVER_URL!"=="" (
    echo.
    echo   ERROR: No URL entered.
    goto :done
)

echo.
echo   Server: !SERVER_URL!
echo   Installing...
echo.

:: Set paths
set "INSTDIR=%ProgramFiles%\PDFEditorSuite"
set "PROGID=PDFEditorSuite.PDF"
set "APPNAME=PDF Editor Suite (Browser)"

:: ============================================================================
:: Step 1: Create install directory
:: ============================================================================
echo   [1/6] Creating install directory...
if not exist "!INSTDIR!" mkdir "!INSTDIR!"
if not exist "!INSTDIR!" (
    echo         ERROR: Could not create !INSTDIR!
    goto :done
)
echo         !INSTDIR!

:: ============================================================================
:: Step 2: Generate all required files
:: ============================================================================
echo   [2/6] Creating scripts...

:: --- open-pdf.bat ---
echo @echo off> "!INSTDIR!\open-pdf.bat"
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%~dp0Open-PDFInBrowser.ps1" "%%~1">> "!INSTDIR!\open-pdf.bat"
echo         open-pdf.bat

:: --- config.ps1 ---
echo $PDFEditorURL = "!SERVER_URL!"> "!INSTDIR!\config.ps1"
echo $RequireLogin = $false>> "!INSTDIR!\config.ps1"
echo $StirlingUsername = "admin">> "!INSTDIR!\config.ps1"
echo $StirlingPassword = "">> "!INSTDIR!\config.ps1"
echo $InstallDir = "$env:ProgramFiles\PDFEditorSuite">> "!INSTDIR!\config.ps1"
echo $ProgId = "!PROGID!">> "!INSTDIR!\config.ps1"
echo $DisplayName = "!APPNAME!">> "!INSTDIR!\config.ps1"
echo         config.ps1

:: --- Open-PDFInBrowser.ps1 ---
set "PS1=!INSTDIR!\Open-PDFInBrowser.ps1"
echo param([Parameter(Mandatory=$true,Position=0)][string]$PdfPath)> "!PS1!"
echo $ErrorActionPreference = "Stop">> "!PS1!"
echo . (Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Definition) "config.ps1")>> "!PS1!"
echo if (-not (Test-Path -LiteralPath $PdfPath)) { exit 1 }>> "!PS1!"
echo $PdfPath = (Resolve-Path -LiteralPath $PdfPath).Path>> "!PS1!"
echo $FileName = [System.IO.Path]::GetFileName($PdfPath)>> "!PS1!"
echo try { Add-Type -AssemblyName System.Windows.Forms; [System.Windows.Forms.Clipboard]::SetDataObject((New-Object System.Windows.Forms.DataObject("FileDrop", [string[]]@($PdfPath))), $true) } catch {}>> "!PS1!"
echo Start-Process "$PDFEditorURL/multi-tool">> "!PS1!"
echo Start-Sleep -Milliseconds 500>> "!PS1!"
echo try {>> "!PS1!"
echo   $n = New-Object System.Windows.Forms.NotifyIcon>> "!PS1!"
echo   $n.Icon = [System.Drawing.SystemIcons]::Information>> "!PS1!"
echo   $n.Visible = $true>> "!PS1!"
echo   $n.BalloonTipTitle = "PDF Editor Suite">> "!PS1!"
echo   $n.BalloonTipText = "$FileName copied to clipboard. Drop or browse to upload in the editor.">> "!PS1!"
echo   $n.ShowBalloonTip(5000)>> "!PS1!"
echo   Start-Sleep -Seconds 6>> "!PS1!"
echo   $n.Dispose()>> "!PS1!"
echo } catch {}>> "!PS1!"
echo exit 0>> "!PS1!"
echo         Open-PDFInBrowser.ps1

:: ============================================================================
:: Step 3: Register file association
:: ============================================================================
echo   [3/6] Registering .pdf file handler...

set "BATPATH=!INSTDIR!\open-pdf.bat"

reg add "HKLM\SOFTWARE\Classes\!PROGID!" /ve /d "!APPNAME!" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\!PROGID!" /v "FriendlyTypeName" /d "!APPNAME!" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\!PROGID!\shell\open\command" /ve /d "\"!BATPATH!\" \"%%1\"" /f >nul 2>&1

:: Back up current handler
set "CUR="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CUR=%%b"
if defined CUR (
    if not "!CUR!"=="!PROGID!" (
        reg add "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /d "!CUR!" /f >nul 2>&1
        echo         Backed up previous handler: !CUR!
    )
)

reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "!PROGID!" /f >nul 2>&1
ftype !PROGID!="!BATPATH!" "%%1" >nul 2>&1
assoc .pdf=!PROGID! >nul 2>&1
echo         .pdf handler registered

:: ============================================================================
:: Step 4: Force Windows 10/11 default app
:: ============================================================================
echo   [4/6] Setting as Windows default PDF app...

reg add "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "!PROGID!" /t REG_NONE /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities" /v "ApplicationName" /d "!APPNAME!" /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities" /v "ApplicationDescription" /d "Opens PDFs in browser-based editor" /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities\FileAssociations" /v ".pdf" /d "!PROGID!" /f >nul 2>&1
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /d "SOFTWARE\PDFEditorSuite\Capabilities" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "!PROGID!" /t REG_NONE /f >nul 2>&1

echo ^<?xml version="1.0" encoding="UTF-8"?^>> "!INSTDIR!\DefaultAssociations.xml"
echo ^<DefaultAssociations^>>> "!INSTDIR!\DefaultAssociations.xml"
echo   ^<Association Identifier=".pdf" ProgId="!PROGID!" ApplicationName="!APPNAME!" /^>>> "!INSTDIR!\DefaultAssociations.xml"
echo ^</DefaultAssociations^>>> "!INSTDIR!\DefaultAssociations.xml"

reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /d "!INSTDIR!\DefaultAssociations.xml" /f >nul 2>&1
echo         Default app set

:: ============================================================================
:: Step 5: Create uninstaller
:: ============================================================================
echo   [5/6] Creating uninstaller...

set "UNI=!INSTDIR!\Uninstall.bat"
echo @echo off> "!UNI!"
echo net session ^>nul 2^>^&1>> "!UNI!"
echo if %%errorlevel%% neq 0 (echo Requesting admin... ^& powershell -Command "Start-Process '%%~f0' -Verb RunAs" ^& exit /b)>> "!UNI!"
echo echo Uninstalling PDF Editor Suite...>> "!UNI!"
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f ^>nul 2^>^&1>> "!UNI!"
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "PDFEditorSuite.PDF" /f ^>nul 2^>^&1>> "!UNI!"
echo reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "PDFEditorSuite.PDF" /f ^>nul 2^>^&1>> "!UNI!"
echo reg delete "HKLM\SOFTWARE\PDFEditorSuite" /f ^>nul 2^>^&1>> "!UNI!"
echo reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /f ^>nul 2^>^&1>> "!UNI!"
echo reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /f ^>nul 2^>^&1>> "!UNI!"
echo reg delete "HKLM\SOFTWARE\Classes\PDFEditorSuite.PDF" /f ^>nul 2^>^&1>> "!UNI!"
echo ftype PDFEditorSuite.PDF= ^>nul 2^>^&1>> "!UNI!"
echo echo [OK] File association removed>> "!UNI!"
echo rmdir /s /q "%%ProgramFiles%%\PDFEditorSuite" 2^>nul>> "!UNI!"
echo echo [OK] Uninstall complete>> "!UNI!"
echo pause>> "!UNI!"
echo         Uninstaller created

:: ============================================================================
:: Step 6: Validate
:: ============================================================================
echo   [6/6] Validating...

set "OK=1"

if exist "!INSTDIR!\config.ps1" (echo         [OK] config.ps1) else (echo         [!!] config.ps1 MISSING & set "OK=0")
if exist "!INSTDIR!\Open-PDFInBrowser.ps1" (echo         [OK] Open-PDFInBrowser.ps1) else (echo         [!!] Open-PDFInBrowser.ps1 MISSING & set "OK=0")
if exist "!INSTDIR!\open-pdf.bat" (echo         [OK] open-pdf.bat) else (echo         [!!] open-pdf.bat MISSING & set "OK=0")

reg query "HKLM\SOFTWARE\Classes\!PROGID!" >nul 2>&1
if !errorlevel! equ 0 (echo         [OK] Registry handler) else (echo         [!!] Registry MISSING & set "OK=0")

reg query "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" >nul 2>&1
if !errorlevel! equ 0 (echo         [OK] Registered as Windows app) else (echo         [!!] App registration MISSING & set "OK=0")

echo.

if "!OK!"=="1" (
    echo   +==========================================================+
    echo   ^|  Setup Complete!                            sariamubeen  ^|
    echo   ^|                                                          ^|
    echo   ^|  Double-click any .pdf to open it in the browser editor. ^|
    echo   ^|                                                          ^|
    echo   ^|  Server: !SERVER_URL!
    echo   ^|  Auth  : No login required                               ^|
    echo   ^|                                                          ^|
    echo   ^|  Uninstall: !INSTDIR!\Uninstall.bat
    echo   +==========================================================+
    echo.
    echo   If .pdf still opens in another app, select
    echo   'PDF Editor Suite (Browser)' in the Settings page opening now...
    echo.
    start ms-settings:defaultapps
) else (
    echo   Setup finished with errors - review output above.
)

:done
echo.
echo   Press any key to close...
pause >nul
endlocal
