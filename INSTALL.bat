@echo off
setlocal

:: ============================================================================
::  PDF Editor Suite - One-Click Installer by sariamubeen
:: ============================================================================

:: Fix working directory (after elevation it defaults to System32)
cd /d "%~dp0"

:: Admin check
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Re-fix directory after elevation
cd /d "%~dp0"

title PDF Editor Suite - Installer
echo.
echo   +==========================================================+
echo   ^|  PDF Editor Suite - One-Click Installer                   ^|
echo   ^|                                          by sariamubeen  ^|
echo   +==========================================================+
echo.

:: Server URL (change here or press Enter to use default)
set "SERVER_URL=http://172.20.4.58:8080"
set /p SERVER_URL="  Server URL [%SERVER_URL%]: "
if "%SERVER_URL%"=="" set "SERVER_URL=http://172.20.4.58:8080"

echo.
echo   Server: %SERVER_URL%
echo.

set "INSTDIR=%ProgramFiles%\PDFEditorSuite"
set "PROGID=PDFEditorSuite.PDF"
set "APPNAME=PDF Editor Suite (Browser)"
set "BATPATH=%INSTDIR%\open-pdf.bat"

:: ── Step 1: Directory ───────────────────────────────────────────────────────
echo   [1/6] Creating install directory...
if not exist "%INSTDIR%" mkdir "%INSTDIR%"
if not exist "%INSTDIR%" (
    echo         ERROR: Cannot create %INSTDIR%
    goto :done
)
echo         OK: %INSTDIR%

:: ── Step 2: Create files ────────────────────────────────────────────────────
echo   [2/6] Creating scripts...

:: Write open-pdf.bat
>"%INSTDIR%\open-pdf.bat" (
echo @echo off
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%~dp0Open-PDFInBrowser.ps1" "%%~1"
)
echo         OK: open-pdf.bat

:: Write config.ps1
>"%INSTDIR%\config.ps1" (
echo $PDFEditorURL = "%SERVER_URL%"
echo $RequireLogin = $false
echo $StirlingUsername = "admin"
echo $StirlingPassword = ""
echo $InstallDir = "$env:ProgramFiles\PDFEditorSuite"
echo $ProgId = "%PROGID%"
echo $DisplayName = "%APPNAME%"
)
echo         OK: config.ps1

:: Write Open-PDFInBrowser.ps1 via base64 decode (zero escaping issues)
set "B64=%temp%\pdfes_handler.b64"
set "TARGET=%INSTDIR%\Open-PDFInBrowser.ps1"
>"%B64%" echo cGFyYW0oW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsUG9zaXRpb249MCldW3N0cmluZ10kUGRmUGF0aCkKaWYgKC1ub3QgKFRlc3QtUGF0aCAtTGl0ZXJhbFBhdGggJFBkZlBhdGgpKSB7IGV4aXQgMSB9CiRQZGZQYXRoID0gKFJlc29sdmUtUGF0aCAtTGl0ZXJhbFBhdGggJFBkZlBhdGgpLlBhdGgKCiMgT3BlbiBkaXJlY3RseSBpbiBFZGdlIG9yIENocm9tZSAoYnlwYXNzZXMgZmlsZSBhc3NvY2lhdGlvbiAtIG5vIGxvb3ApCiRlZGdlID0gIiR7ZW52OlByb2dyYW1GaWxlcyh4ODYpfVxNaWNyb3NvZnRcRWRnZVxBcHBsaWNhdGlvblxtc2VkZ2UuZXhlIgokY2hyb21lID0gIiRlbnY6UHJvZ3JhbUZpbGVzXEdvb2dsZVxDaHJvbWVcQXBwbGljYXRpb25cY2hyb21lLmV4ZSIKaWYgKFRlc3QtUGF0aCAkZWRnZSkgewogICAgU3RhcnQtUHJvY2VzcyAkZWRnZSAtQXJndW1lbnRMaXN0ICJgIiRQZGZQYXRoYCIiCn0gZWxzZWlmIChUZXN0LVBhdGggJGNocm9tZSkgewogICAgU3RhcnQtUHJvY2VzcyAkY2hyb21lIC1Bcmd1bWVudExpc3QgImAiJFBkZlBhdGhgIiIKfSBlbHNlIHsKICAgIFN0YXJ0LVByb2Nlc3MgImV4cGxvcmVyLmV4ZSIgLUFyZ3VtZW50TGlzdCAiYCIkUGRmUGF0aGAiIgp9CmV4aXQgMAo=
certutil -decode "%B64%" "%TARGET%" >nul 2>&1
del /q "%B64%" >nul 2>&1
if not exist "%TARGET%" (
    echo         ERROR: Failed to create handler script
    goto :done
)
echo         OK: Open-PDFInBrowser.ps1

:: ── Step 3: Register handler ────────────────────────────────────────────────
echo   [3/6] Registering file handler...

reg add "HKLM\SOFTWARE\Classes\%PROGID%" /ve /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%" /v "FriendlyTypeName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\Classes\%PROGID%\shell\open\command" /ve /d "\"%BATPATH%\" \"%%1\"" /f >nul 2>&1

set "CUR="
for /f "tokens=2*" %%a in ('reg query "HKLM\SOFTWARE\Classes\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CUR=%%b"
if defined CUR (
    if not "%CUR%"=="%PROGID%" (
        reg add "HKLM\SOFTWARE\Classes\.pdf" /v "PDFEditorSuite_PreviousHandler" /d "%CUR%" /f >nul 2>&1
        echo         Backed up: %CUR%
    )
)

reg add "HKLM\SOFTWARE\Classes\.pdf" /ve /d "%PROGID%" /f >nul 2>&1
ftype %PROGID%="%BATPATH%" "%%1" >nul 2>&1
assoc .pdf=%PROGID% >nul 2>&1
echo         OK: .pdf handler registered

:: ── Step 4: Windows 10/11 default app ───────────────────────────────────────
echo   [4/6] Setting as default PDF app...

reg add "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities" /v "ApplicationName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities" /v "ApplicationDescription" /d "Opens PDFs in browser-based editor" /f >nul 2>&1
reg add "HKLM\SOFTWARE\PDFEditorSuite\Capabilities\FileAssociations" /v ".pdf" /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /d "SOFTWARE\PDFEditorSuite\Capabilities" /f >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f >nul 2>&1
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1

>"%INSTDIR%\DefaultAssociations.xml" (
echo ^<?xml version="1.0" encoding="UTF-8"?^>
echo ^<DefaultAssociations^>
echo   ^<Association Identifier=".pdf" ProgId="%PROGID%" ApplicationName="%APPNAME%" /^>
echo ^</DefaultAssociations^>
)
reg add "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /d "%INSTDIR%\DefaultAssociations.xml" /f >nul 2>&1
echo         OK: Default app set

:: ── Step 5: Create uninstaller ──────────────────────────────────────────────
echo   [5/6] Creating uninstaller...

>"%INSTDIR%\Uninstall.bat" (
echo @echo off
echo net session ^>nul 2^>^&1
echo if %%errorlevel%% neq 0 ^(powershell -Command "Start-Process '%%~f0' -Verb RunAs" ^& exit /b^)
echo echo Uninstalling PDF Editor Suite...
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f ^>nul 2^>^&1
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "PDFEditorSuite.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "PDFEditorSuite.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\PDFEditorSuite" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "PDFEditorSuite" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\PDFEditorSuite.PDF" /f ^>nul 2^>^&1
echo ftype PDFEditorSuite.PDF= ^>nul 2^>^&1
echo echo [OK] Removed
echo rmdir /s /q "%%ProgramFiles%%\PDFEditorSuite" 2^>nul
echo echo Done.
echo pause
)
echo         OK: Uninstaller created

:: ── Step 6: Validate ────────────────────────────────────────────────────────
echo   [6/6] Validating...

set "FAIL=0"
if exist "%INSTDIR%\config.ps1" (echo         [OK] config.ps1) else (echo         [!!] config.ps1 & set "FAIL=1")
if exist "%INSTDIR%\Open-PDFInBrowser.ps1" (echo         [OK] Open-PDFInBrowser.ps1) else (echo         [!!] Open-PDFInBrowser.ps1 & set "FAIL=1")
if exist "%INSTDIR%\open-pdf.bat" (echo         [OK] open-pdf.bat) else (echo         [!!] open-pdf.bat & set "FAIL=1")

reg query "HKLM\SOFTWARE\Classes\%PROGID%" >nul 2>&1
if %errorlevel% equ 0 (echo         [OK] Registry) else (echo         [!!] Registry & set "FAIL=1")

echo.

if "%FAIL%"=="0" (
    echo   +==========================================================+
    echo   ^|  Setup Complete!                            sariamubeen  ^|
    echo   ^|                                                          ^|
    echo   ^|  Double-click any .pdf to open it in the browser editor. ^|
    echo   ^|  Server: %SERVER_URL%
    echo   ^|  Auth  : No login required                               ^|
    echo   ^|  Uninstall: %INSTDIR%\Uninstall.bat
    echo   +==========================================================+
    echo.
    echo   Opening Default Apps settings - select PDF Editor Suite...
    start ms-settings:defaultapps
) else (
    echo   Setup had errors. Review output above.
)

:done
echo.
pause
endlocal
