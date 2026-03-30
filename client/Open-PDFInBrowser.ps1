<#
.SYNOPSIS
    Opens a PDF file in Stirling-PDF via the default web browser.

.DESCRIPTION
    Called by Windows file association when a user double-clicks a .pdf file.
    Copies the file path to the clipboard, then launches the browser to the
    Stirling-PDF server where the user can upload, edit, annotate, and sign.

.PARAMETER PdfPath
    Full path to the PDF file (passed by Windows shell).

.NOTES
    Part of PDF Editor Suite.
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

# ── Launch browser ───────────────────────────────────────────────────────────

try {
    Start-Process "$PDFEditorURL"
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
