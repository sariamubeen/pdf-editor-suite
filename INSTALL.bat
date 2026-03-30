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
>"%B64%" echo cGFyYW0oW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsUG9zaXRpb249MCldW3N0cmluZ10kUGRmUGF0aCkKJEVycm9yQWN0aW9uUHJlZmVyZW5jZSA9ICJTdG9wIgouIChKb2luLVBhdGggKFNwbGl0LVBhdGggLVBhcmVudCAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5EZWZpbml0aW9uKSAiY29uZmlnLnBzMSIpCmlmICgtbm90IChUZXN0LVBhdGggLUxpdGVyYWxQYXRoICRQZGZQYXRoKSkgeyBleGl0IDEgfQokUGRmUGF0aCA9IChSZXNvbHZlLVBhdGggLUxpdGVyYWxQYXRoICRQZGZQYXRoKS5QYXRoCiRGaWxlTmFtZSA9IFtTeXN0ZW0uSU8uUGF0aF06OkdldEZpbGVOYW1lKCRQZGZQYXRoKQokZmlsZUJ5dGVzID0gW1N5c3RlbS5JTy5GaWxlXTo6UmVhZEFsbEJ5dGVzKCRQZGZQYXRoKQokYjY0ID0gW0NvbnZlcnRdOjpUb0Jhc2U2NFN0cmluZygkZmlsZUJ5dGVzKQoKIyBQaWNrIGEgcmFuZG9tIHBvcnQgZm9yIHRoZSBsb2NhbCBzZXJ2ZXIKJHBvcnQgPSBHZXQtUmFuZG9tIC1NaW5pbXVtIDQ5MTUyIC1NYXhpbXVtIDY1NTM1CgojIEJ1aWxkIEhUTUwgdGhhdCBhdXRvLXVwbG9hZHMgdGhlIFBERiB0byBTdGlybGluZy1QREYgbXVsdGktdG9vbAokaHRtbCA9IEAiCjwhRE9DVFlQRSBodG1sPgo8aHRtbD4KPGhlYWQ+PHRpdGxlPlBERiBFZGl0b3IgU3VpdGUgLSBMb2FkaW5nLi4uPC90aXRsZT48L2hlYWQ+Cjxib2R5IHN0eWxlPSJmb250LWZhbWlseTpzYW5zLXNlcmlmO2Rpc3BsYXk6ZmxleDtmbGV4LWRpcmVjdGlvbjpjb2x1bW47YWxpZ24taXRlbXM6Y2VudGVyO2p1c3RpZnktY29udGVudDpjZW50ZXI7aGVpZ2h0OjEwMHZoO21hcmdpbjowO2JhY2tncm91bmQ6I2Y1ZjVmNSI+CjxoMj5QREYgRWRpdG9yIFN1aXRlPC9oMj4KPHAgaWQ9InN0YXR1cyI+VXBsb2FkaW5nICRGaWxlTmFtZSB0byBlZGl0b3IuLi48L3A+CjxzY3JpcHQ+CihmdW5jdGlvbigpewogIHZhciBiNjQgPSAiJGI2NCI7CiAgdmFyIGJpbiA9IGF0b2IoYjY0KTsKICB2YXIgYXJyID0gbmV3IFVpbnQ4QXJyYXkoYmluLmxlbmd0aCk7CiAgZm9yKHZhciBpPTA7aTxiaW4ubGVuZ3RoO2krKykgYXJyW2ldPWJpbi5jaGFyQ29kZUF0KGkpOwogIHZhciBmaWxlID0gbmV3IEZpbGUoW2Fycl0sICIkRmlsZU5hbWUiLCB7dHlwZToiYXBwbGljYXRpb24vcGRmIn0pOwoKICAvLyBOYXZpZ2F0ZSB0byBTdGlybGluZy1QREYgbXVsdGktdG9vbCwgdGhlbiBpbmplY3QgdGhlIGZpbGUKICB2YXIgc2VydmVyVXJsID0gIiRQREZFZGl0b3JVUkwiOwogIHZhciBpZnJhbWUgPSBkb2N1bWVudC5jcmVhdGVFbGVtZW50KCJpZnJhbWUiKTsKICBpZnJhbWUuc3R5bGUuZGlzcGxheSA9ICJub25lIjsKICBpZnJhbWUuc3JjID0gc2VydmVyVXJsICsgIi9tdWx0aS10b29sIjsKICBkb2N1bWVudC5ib2R5LmFwcGVuZENoaWxkKGlmcmFtZSk7CgogIC8vIFdhaXQgZm9yIG11bHRpLXRvb2wgcGFnZSB0byBsb2FkLCB0aGVuIHVzZSBwb3N0TWVzc2FnZSBvciBkaXJlY3QgbWFuaXB1bGF0aW9uCiAgLy8gU2luY2Ugd2UgY2FuJ3QgaW5qZWN0IGludG8gY3Jvc3Mtb3JpZ2luIGlmcmFtZSwgcmVkaXJlY3QgaW5zdGVhZAogIC8vIFN0b3JlIGZpbGUgaW4gc2Vzc2lvblN0b3JhZ2UtbGlrZSBtZWNoYW5pc20gdmlhIHRoZSBBUEkKCiAgLy8gQmV0dGVyIGFwcHJvYWNoOiB1c2UgdGhlIFN0aXJsaW5nLVBERiBBUEkgdG8gZ2V0IGEgdmlld2FibGUgcmVzdWx0CiAgdmFyIGZkID0gbmV3IEZvcm1EYXRhKCk7CiAgZmQuYXBwZW5kKCJmaWxlSW5wdXQiLCBmaWxlKTsKICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgic3RhdHVzIikudGV4dENvbnRlbnQgPSAiUHJvY2Vzc2luZyAkRmlsZU5hbWUuLi4iOwoKICBmZXRjaChzZXJ2ZXJVcmwgKyAiL2FwaS92MS9nZW5lcmFsL2ZsYXR0ZW4iLCB7bWV0aG9kOiJQT1NUIiwgYm9keTpmZH0pCiAgLnRoZW4oZnVuY3Rpb24ocil7CiAgICBpZighci5vaykgdGhyb3cgbmV3IEVycm9yKCJBUEkgcmV0dXJuZWQgIiArIHIuc3RhdHVzKTsKICAgIHJldHVybiByLmJsb2IoKTsKICB9KQogIC50aGVuKGZ1bmN0aW9uKGJsb2IpewogICAgdmFyIHVybCA9IFVSTC5jcmVhdGVPYmplY3RVUkwoYmxvYik7CiAgICBkb2N1bWVudC5nZXRFbGVtZW50QnlJZCgic3RhdHVzIikudGV4dENvbnRlbnQgPSAiT3BlbmluZyBQREYuLi4iOwogICAgLy8gT3BlbiB0aGUgUERGIGRpcmVjdGx5IGluIHRoaXMgdGFiCiAgICB3aW5kb3cubG9jYXRpb24gPSB1cmw7CiAgfSkKICAuY2F0Y2goZnVuY3Rpb24oZXJyKXsKICAgIGRvY3VtZW50LmdldEVsZW1lbnRCeUlkKCJzdGF0dXMiKS50ZXh0Q29udGVudCA9ICJSZWRpcmVjdGluZyB0byBlZGl0b3IuLi4iOwogICAgLy8gRmFsbGJhY2s6IGp1c3QgZ28gdG8gdGhlIFN0aXJsaW5nLVBERiBob21lcGFnZQogICAgc2V0VGltZW91dChmdW5jdGlvbigpeyB3aW5kb3cubG9jYXRpb24gPSBzZXJ2ZXJVcmw7IH0sIDEwMDApOwogIH0pOwp9KSgpOwo8L3NjcmlwdD4KPC9ib2R5Pgo8L2h0bWw+CiJACgojIFN0YXJ0IGEgdGlueSBIVFRQIHNlcnZlciB0aGF0IHNlcnZlcyB0aGlzIEhUTUwgcGFnZSwgdGhlbiB0aGUgYnJvd3NlciBvcGVucyBpdAokbGlzdGVuZXIgPSBOZXctT2JqZWN0IFN5c3RlbS5OZXQuSHR0cExpc3RlbmVyCiRsaXN0ZW5lci5QcmVmaXhlcy5BZGQoImh0dHA6Ly9sb2NhbGhvc3Q6JHBvcnQvIikKdHJ5IHsKICAgICRsaXN0ZW5lci5TdGFydCgpCn0gY2F0Y2ggewogICAgIyBQb3J0IGluIHVzZSwgdHJ5IGFub3RoZXIKICAgICRwb3J0ID0gR2V0LVJhbmRvbSAtTWluaW11bSA0OTE1MiAtTWF4aW11bSA2NTUzNQogICAgJGxpc3RlbmVyID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHBMaXN0ZW5lcgogICAgJGxpc3RlbmVyLlByZWZpeGVzLkFkZCgiaHR0cDovL2xvY2FsaG9zdDokcG9ydC8iKQogICAgJGxpc3RlbmVyLlN0YXJ0KCkKfQoKIyBPcGVuIGJyb3dzZXIgdG8gb3VyIGxvY2FsIHNlcnZlcgpTdGFydC1Qcm9jZXNzICJodHRwOi8vbG9jYWxob3N0OiRwb3J0LyIKCiMgU2VydmUgZXhhY3RseSBvbmUgcmVxdWVzdCB0aGVuIHNodXQgZG93bgokY29udGV4dCA9ICRsaXN0ZW5lci5HZXRDb250ZXh0KCkKJHJlc3BvbnNlID0gJGNvbnRleHQuUmVzcG9uc2UKJGJ1ZmZlciA9IFtTeXN0ZW0uVGV4dC5FbmNvZGluZ106OlVURjguR2V0Qnl0ZXMoJGh0bWwpCiRyZXNwb25zZS5Db250ZW50VHlwZSA9ICJ0ZXh0L2h0bWw7IGNoYXJzZXQ9dXRmLTgiCiRyZXNwb25zZS5Db250ZW50TGVuZ3RoNjQgPSAkYnVmZmVyLkxlbmd0aAokcmVzcG9uc2UuT3V0cHV0U3RyZWFtLldyaXRlKCRidWZmZXIsIDAsICRidWZmZXIuTGVuZ3RoKQokcmVzcG9uc2UuT3V0cHV0U3RyZWFtLkNsb3NlKCkKCiMgS2VlcCBzZXJ2ZXIgYWxpdmUgYnJpZWZseSBmb3IgYW55IHN1Yi1yZXF1ZXN0cywgdGhlbiBjbGVhbiB1cApTdGFydC1TbGVlcCAtU2Vjb25kcyAyCiRsaXN0ZW5lci5TdG9wKCkKJGxpc3RlbmVyLkNsb3NlKCkKZXhpdCAwCg==
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
