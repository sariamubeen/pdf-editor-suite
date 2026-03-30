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

:: Get server URL
set "SERVER_URL="
set /p SERVER_URL="  Enter your server URL (e.g. http://192.168.1.50:8080): "
if "%SERVER_URL%"=="" (
    echo   ERROR: No URL entered.
    goto :done
)

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
>"%B64%" echo cGFyYW0oW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsUG9zaXRpb249MCldW3N0cmluZ10kUGRmUGF0aCkKJEVycm9yQWN0aW9uUHJlZmVyZW5jZSA9ICJTdG9wIgouIChKb2luLVBhdGggKFNwbGl0LVBhdGggLVBhcmVudCAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5EZWZpbml0aW9uKSAiY29uZmlnLnBzMSIpCmlmICgtbm90IChUZXN0LVBhdGggLUxpdGVyYWxQYXRoICRQZGZQYXRoKSkgeyBleGl0IDEgfQokUGRmUGF0aCA9IChSZXNvbHZlLVBhdGggLUxpdGVyYWxQYXRoICRQZGZQYXRoKS5QYXRoCiRGaWxlTmFtZSA9IFtTeXN0ZW0uSU8uUGF0aF06OkdldEZpbGVOYW1lKCRQZGZQYXRoKQoKIyBUcnkgdG8gdXBsb2FkIFBERiB0byBTdGlybGluZy1QREYgQVBJIGFuZCBvcGVuIHJlc3VsdCBpbiBicm93c2VyCnRyeSB7CiAgICAkYm91bmRhcnkgPSBbZ3VpZF06Ok5ld0d1aWQoKS5Ub1N0cmluZygpCiAgICAkZmlsZUJ5dGVzID0gW1N5c3RlbS5JTy5GaWxlXTo6UmVhZEFsbEJ5dGVzKCRQZGZQYXRoKQogICAgJGVuYyA9IFtTeXN0ZW0uVGV4dC5FbmNvZGluZ106OkdldEVuY29kaW5nKCJpc28tODg1OS0xIikKICAgICRoZHIgPSAiLS0kYm91bmRhcnlgcmBuQ29udGVudC1EaXNwb3NpdGlvbjogZm9ybS1kYXRhOyBuYW1lPWAiZmlsZUlucHV0YCI7IGZpbGVuYW1lPWAiJEZpbGVOYW1lYCJgcmBuQ29udGVudC1UeXBlOiBhcHBsaWNhdGlvbi9wZGZgcmBuYHJgbiIKICAgICRmdHIgPSAiYHJgbi0tJGJvdW5kYXJ5LS1gcmBuIgogICAgJGJvZHkgPSAkZW5jLkdldEJ5dGVzKCRoZHIpICsgJGZpbGVCeXRlcyArICRlbmMuR2V0Qnl0ZXMoJGZ0cikKICAgICR0bXBPdXQgPSBKb2luLVBhdGggKFtTeXN0ZW0uSU8uUGF0aF06OkdldFRlbXBQYXRoKCkpICgicGRmZWRpdC0iICsgW2d1aWRdOjpOZXdHdWlkKCkuVG9TdHJpbmcoIk4iKS5TdWJzdHJpbmcoMCw4KSArICIucGRmIikKICAgICR1cmwgPSAiJFBERkVkaXRvclVSTC9hcGkvdjEvZ2VuZXJhbC9mbGF0dGVuIgogICAgSW52b2tlLVdlYlJlcXVlc3QgLVVyaSAkdXJsIC1NZXRob2QgUE9TVCAtQ29udGVudFR5cGUgIm11bHRpcGFydC9mb3JtLWRhdGE7IGJvdW5kYXJ5PSRib3VuZGFyeSIgLUJvZHkgJGJvZHkgLU91dEZpbGUgJHRtcE91dCAtVXNlQmFzaWNQYXJzaW5nIC1UaW1lb3V0U2VjIDYwIC1FcnJvckFjdGlvbiBTdG9wCgogICAgIyBPcGVuIGluIGJyb3dzZXIgZGlyZWN0bHkgKG5vdCB0aHJvdWdoIG91ciBoYW5kbGVyIC0gYXZvaWRzIGluZmluaXRlIGxvb3ApCiAgICAkZWRnZSA9ICIke2VudjpQcm9ncmFtRmlsZXMoeDg2KX1cTWljcm9zb2Z0XEVkZ2VcQXBwbGljYXRpb25cbXNlZGdlLmV4ZSIKICAgICRjaHJvbWUgPSAiJGVudjpQcm9ncmFtRmlsZXNcR29vZ2xlXENocm9tZVxBcHBsaWNhdGlvblxjaHJvbWUuZXhlIgogICAgaWYgKFRlc3QtUGF0aCAkZWRnZSkgeyBTdGFydC1Qcm9jZXNzICRlZGdlIC1Bcmd1bWVudExpc3QgImAiJHRtcE91dGAiIiB9CiAgICBlbHNlaWYgKFRlc3QtUGF0aCAkY2hyb21lKSB7IFN0YXJ0LVByb2Nlc3MgJGNocm9tZSAtQXJndW1lbnRMaXN0ICJgIiR0bXBPdXRgIiIgfQogICAgZWxzZSB7IFN0YXJ0LVByb2Nlc3MgImV4cGxvcmVyLmV4ZSIgLUFyZ3VtZW50TGlzdCAiYCIkdG1wT3V0YCIiIH0KfSBjYXRjaCB7CiAgICAjIEFQSSBmYWlsZWQgLSBvcGVuIFN0aXJsaW5nLVBERiBob21lcGFnZSwgY29weSBmaWxlIHBhdGggdG8gY2xpcGJvYXJkCiAgICB0cnkgewogICAgICAgIEFkZC1UeXBlIC1Bc3NlbWJseU5hbWUgU3lzdGVtLldpbmRvd3MuRm9ybXMKICAgICAgICBbU3lzdGVtLldpbmRvd3MuRm9ybXMuQ2xpcGJvYXJkXTo6U2V0VGV4dCgkUGRmUGF0aCkKICAgIH0gY2F0Y2gge30KICAgIFN0YXJ0LVByb2Nlc3MgIiRQREZFZGl0b3JVUkwiCn0KZXhpdCAwCg==
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
