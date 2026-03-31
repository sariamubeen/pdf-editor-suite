@echo off
setlocal

:: ============================================================================
::  SIERA PDF - One-Click Installer
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

title SIERA PDF - Installer
echo.
echo   +==========================================================+
echo   ^|  SIERA PDF - Installer                                    ^|
echo   +==========================================================+
echo.

:: Server URL
set "SERVER_URL=http://172.20.4.58:8080"
set /p SERVER_URL="  Server URL [%SERVER_URL%]: "
if "%SERVER_URL%"=="" set "SERVER_URL=http://172.20.4.58:8080"

echo.
echo   Server: %SERVER_URL%
echo.

set "INSTDIR=%ProgramFiles%\SieraPDF"
set "PROGID=SieraPDF.PDF"
set "APPNAME=SIERA PDF"
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
echo $InstallDir = "$env:ProgramFiles\SieraPDF"
echo $ProgId = "%PROGID%"
echo $DisplayName = "%APPNAME%"
)
echo         OK: config.ps1

:: Write Open-PDFInBrowser.ps1 via base64 decode
set "B64=%temp%\siera_handler.b64"
set "TARGET=%INSTDIR%\Open-PDFInBrowser.ps1"
>"%B64%" echo cGFyYW0oW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsUG9zaXRpb249MCldW3N0cmluZ10kUGRmUGF0aCkKCiRsb2dGaWxlID0gSm9pbi1QYXRoIChbU3lzdGVtLklPLlBhdGhdOjpHZXRUZW1wUGF0aCgpKSAiU2llcmFQREYtZGVidWcubG9nIgpmdW5jdGlvbiBMb2coJG1zZykgewogICAgJHRzID0gR2V0LURhdGUgLUZvcm1hdCAieXl5eS1NTS1kZCBISDptbTpzcyIKICAgICIkdHMgICRtc2ciIHwgT3V0LUZpbGUgLUFwcGVuZCAtRmlsZVBhdGggJGxvZ0ZpbGUgLUVuY29kaW5nIFVURjgKfQoKTG9nICI9PT0gU0lFUkEgUERGIEhhbmRsZXIgc3RhcnRlZCA9PT0iCkxvZyAiUGRmUGF0aDogJFBkZlBhdGgiCgouIChKb2luLVBhdGggKFNwbGl0LVBhdGggLVBhcmVudCAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5EZWZpbml0aW9uKSAiY29uZmlnLnBzMSIpCkxvZyAiU2VydmVyOiAkUERGRWRpdG9yVVJMIgoKaWYgKC1ub3QgKFRlc3QtUGF0aCAtTGl0ZXJhbFBhdGggJFBkZlBhdGgpKSB7CiAgICBMb2cgIkVSUk9SOiBGaWxlIG5vdCBmb3VuZDogJFBkZlBhdGgiCiAgICBleGl0IDEKfQokUGRmUGF0aCA9IChSZXNvbHZlLVBhdGggLUxpdGVyYWxQYXRoICRQZGZQYXRoKS5QYXRoCiRGaWxlTmFtZSA9IFtTeXN0ZW0uSU8uUGF0aF06OkdldEZpbGVOYW1lKCRQZGZQYXRoKQpMb2cgIkZpbGU6ICRQZGZQYXRoIgoKdHJ5IHsKICAgIExvZyAiVXBsb2FkaW5nIHRvICRQREZFZGl0b3JVUkwvYXBpL3VwbG9hZCAuLi4iCiAgICBBZGQtVHlwZSAtQXNzZW1ibHlOYW1lIFN5c3RlbS5OZXQuSHR0cAogICAgJGNsaWVudCA9IE5ldy1PYmplY3QgU3lzdGVtLk5ldC5IdHRwLkh0dHBDbGllbnQKICAgICRjb250ZW50ID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHAuTXVsdGlwYXJ0Rm9ybURhdGFDb250ZW50CiAgICAkZmlsZVN0cmVhbSA9IFtTeXN0ZW0uSU8uRmlsZV06Ok9wZW5SZWFkKCRQZGZQYXRoKQogICAgJGZpbGVDb250ZW50ID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHAuU3RyZWFtQ29udGVudCgkZmlsZVN0cmVhbSkKICAgICRmaWxlQ29udGVudC5IZWFkZXJzLkNvbnRlbnRUeXBlID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHAuSGVhZGVycy5NZWRpYVR5cGVIZWFkZXJWYWx1ZSgiYXBwbGljYXRpb24vcGRmIikKICAgICRjb250ZW50LkFkZCgkZmlsZUNvbnRlbnQsICJmaWxlIiwgJEZpbGVOYW1lKQogICAgJHJlc3BvbnNlID0gJGNsaWVudC5Qb3N0QXN5bmMoIiRQREZFZGl0b3JVUkwvYXBpL3VwbG9hZCIsICRjb250ZW50KS5SZXN1bHQKICAgICRib2R5ID0gJHJlc3BvbnNlLkNvbnRlbnQuUmVhZEFzU3RyaW5nQXN5bmMoKS5SZXN1bHQKICAgICRmaWxlU3RyZWFtLkNsb3NlKCkKICAgICRjbGllbnQuRGlzcG9zZSgpCiAgICBMb2cgIlJlc3BvbnNlOiAkKCRyZXNwb25zZS5TdGF0dXNDb2RlKSAtICRib2R5IgogICAgJGpzb24gPSAkYm9keSB8IENvbnZlcnRGcm9tLUpzb24KICAgICRlZGl0VXJsID0gJGpzb24udXJsCiAgICBMb2cgIkVkaXQgVVJMOiAkZWRpdFVybCIKICAgIFN0YXJ0LVByb2Nlc3MgJGVkaXRVcmwKICAgIExvZyAiQnJvd3NlciBvcGVuZWQiCn0gY2F0Y2ggewogICAgTG9nICJFUlJPUjogJCgkXy5FeGNlcHRpb24uTWVzc2FnZSkiCiAgICBTdGFydC1Qcm9jZXNzICIkUERGRWRpdG9yVVJMIgp9CgpMb2cgIj09PSBTSUVSQSBQREYGSW5kbGVyIGZpbmlzaGVkID09PSIKZXhpdCAwCg==
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
        reg add "HKLM\SOFTWARE\Classes\.pdf" /v "SieraPDF_PreviousHandler" /d "%CUR%" /f >nul 2>&1
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
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities" /v "ApplicationDescription" /d "SIERA PDF - Edit, annotate, and sign PDFs" /f >nul 2>&1
reg add "HKLM\SOFTWARE\SieraPDF\Capabilities\FileAssociations" /v ".pdf" /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /d "SOFTWARE\SieraPDF\Capabilities" /f >nul 2>&1
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
echo echo Uninstalling SIERA PDF...
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\UserChoice" /f ^>nul 2^>^&1
echo reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FileExts\.pdf\OpenWithProgids" /v "SieraPDF.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\.pdf\OpenWithProgids" /v "SieraPDF.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\SieraPDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\RegisteredApplications" /v "SieraPDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Policies\Microsoft\Windows\System" /v "DefaultAssociationsConfiguration" /f ^>nul 2^>^&1
echo reg delete "HKLM\SOFTWARE\Classes\SieraPDF.PDF" /f ^>nul 2^>^&1
echo ftype SieraPDF.PDF= ^>nul 2^>^&1
echo echo [OK] Removed
echo rmdir /s /q "%%ProgramFiles%%\SieraPDF" 2^>nul
echo echo SIERA PDF has been uninstalled.
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
    echo   ^|  SIERA PDF - Setup Complete!                              ^|
    echo   ^|                                                          ^|
    echo   ^|  Double-click any .pdf to open it in the browser editor. ^|
    echo   ^|  Or right-click ^> Open with ^> SIERA PDF                 ^|
    echo   ^|                                                          ^|
    echo   ^|  Server: %SERVER_URL%
    echo   ^|  Uninstall: %INSTDIR%\Uninstall.bat
    echo   +==========================================================+
) else (
    echo   Setup had errors. Review output above.
)

:done
echo.
pause
endlocal
