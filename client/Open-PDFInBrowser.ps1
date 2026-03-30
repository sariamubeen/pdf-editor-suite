<#
.SYNOPSIS
    Opens a PDF file in Stirling-PDF via the default web browser.

.DESCRIPTION
    Called by Windows file association when a user double-clicks a .pdf file.
    If the server requires login, the script authenticates via the API first
    and passes the session cookie to the browser so the user is never prompted.
    If login is disabled, it simply opens the browser directly.

.PARAMETER PdfPath
    Full path to the PDF file (passed by Windows shell).

.NOTES
    Part of PDF Editor Suite by sariamubeen.
    Configuration is read from config.ps1 in the same directory.
#>

param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$PdfPath
)

$ErrorActionPreference = "Stop"

# ── Load configuration ───────────────────────────────────────────────────────

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "config.ps1"

if (-not (Test-Path $ConfigFile)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Configuration file not found:`n$ConfigFile`n`nReinstall PDF Editor Suite.",
        "PDF Editor Suite - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

. $ConfigFile

# ── Validate the PDF file ────────────────────────────────────────────────────

if (-not (Test-Path -LiteralPath $PdfPath)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "File not found:`n$PdfPath",
        "PDF Editor Suite - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

$Extension = [System.IO.Path]::GetExtension($PdfPath).ToLower()
if ($Extension -ne ".pdf") {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Not a PDF file:`n$PdfPath",
        "PDF Editor Suite - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# Resolve to absolute path
$PdfPath = (Resolve-Path -LiteralPath $PdfPath).Path
$FileName = [System.IO.Path]::GetFileName($PdfPath)

# ── Copy file path to clipboard ──────────────────────────────────────────────

try {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.Clipboard]::SetText($PdfPath)
}
catch {
    # Clipboard access can fail in some session types — non-fatal
}

# ── Auto-login if server requires authentication ─────────────────────────────

$LaunchURL = $PDFEditorURL

if ($RequireLogin -eq $true) {
    try {
        # Create a web session to capture cookies
        $LoginBody = @{
            username = $StirlingUsername
            password = $StirlingPassword
        }

        # Authenticate and get session cookie
        $Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        $LoginResponse = Invoke-WebRequest -Uri "$PDFEditorURL/login" -Method POST -Body $LoginBody -WebSession $Session -UseBasicParsing -MaximumRedirection 5 -TimeoutSec 15 -ErrorAction Stop

        # Extract JSESSIONID cookie from the session
        $SessionCookie = $Session.Cookies.GetCookies($PDFEditorURL) | Where-Object { $_.Name -eq "JSESSIONID" }

        if ($SessionCookie) {
            # Write cookie to a temp file for the browser
            # Most browsers accept cookies set via the URL session, but we'll use
            # a different approach: open the login URL with credentials as a form POST
            # by writing a small HTML auto-submit form
            $TempHtml = [System.IO.Path]::Combine([System.IO.Path]::GetTempPath(), "pdf-editor-login.html")
            $HtmlLines = @(
                '<!DOCTYPE html>'
                '<html>'
                '<head><title>PDF Editor Suite</title></head>'
                '<body>'
                "<form id=`"loginForm`" method=`"POST`" action=`"$PDFEditorURL/login`">"
                "  <input type=`"hidden`" name=`"username`" value=`"$StirlingUsername`" />"
                "  <input type=`"hidden`" name=`"password`" value=`"$StirlingPassword`" />"
                '</form>'
                "<script>document.getElementById('loginForm').submit();</script>"
                '</body>'
                '</html>'
            )
            $HtmlContent = $HtmlLines -join "`r`n"
            Set-Content -Path $TempHtml -Value $HtmlContent -Encoding UTF8
            $LaunchURL = $TempHtml

            # Schedule cleanup of temp file after 10 seconds
            Start-Job -ScriptBlock {
                param($f)
                Start-Sleep -Seconds 10
                Remove-Item -Path $f -Force -ErrorAction SilentlyContinue
            } -ArgumentList $TempHtml | Out-Null
        }
    }
    catch {
        # Auto-login failed — fall back to opening the URL directly (user will see login page)
    }
}

# ── Launch browser ───────────────────────────────────────────────────────────

try {
    Start-Process "$LaunchURL"
}
catch {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show(
        "Could not open browser.`n`nURL: $PDFEditorURL`nError: $($_.Exception.Message)",
        "PDF Editor Suite - Error",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Error
    ) | Out-Null
    exit 1
}

# ── Show notification ────────────────────────────────────────────────────────

try {
    $Notification = New-Object System.Windows.Forms.NotifyIcon
    $Notification.Icon = [System.Drawing.SystemIcons]::Information
    $Notification.Visible = $true
    $Notification.BalloonTipTitle = "PDF Editor Suite"
    $Notification.BalloonTipText = "Opening '$FileName' — file path copied to clipboard."
    $Notification.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::Info
    $Notification.ShowBalloonTip(4000)

    # Keep the script alive briefly so the notification displays
    Start-Sleep -Seconds 5
    $Notification.Dispose()
}
catch {
    # Notification failed — non-fatal, browser already opened
}

exit 0
