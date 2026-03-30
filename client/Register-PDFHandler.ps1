<#
.SYNOPSIS
    Registers PDF Editor Suite as the handler for .pdf files on Windows.

.DESCRIPTION
    Run this script ONCE as Administrator on each Windows machine.
    It installs the handler scripts and registers the .pdf file association
    so that double-clicking a PDF opens the browser-based editor.

.NOTES
    Part of PDF Editor Suite.
    Requires: Administrator privileges.
    Tested:   Windows 10, Windows 11, Windows Server 2019/2022/2025.
#>

# ── Require admin ────────────────────────────────────────────────────────────

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host ""
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "Right-click the script and select 'Run with PowerShell as Administrator'," -ForegroundColor Yellow
    Write-Host "or open an elevated PowerShell prompt first." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

$ErrorActionPreference = "Stop"

# ── Load configuration ───────────────────────────────────────────────────────

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "config.ps1"

if (-not (Test-Path $ConfigFile)) {
    Write-Host "ERROR: config.ps1 not found in $ScriptDir" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

. $ConfigFile

# ── Validate config ──────────────────────────────────────────────────────────

if ($PDFEditorURL -eq "https://pdf.example.com") {
    Write-Host ""
    Write-Host "WARNING: You haven't configured the server URL yet!" -ForegroundColor Yellow
    Write-Host "Edit config.ps1 and set `$PDFEditorURL to your Stirling-PDF server URL." -ForegroundColor Yellow
    Write-Host ""
    $continue = Read-Host "Continue anyway? (y/N)"
    if ($continue -ne "y") { exit 0 }
}

# ── Banner ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║  PDF Editor Suite — Windows Client Setup             ║" -ForegroundColor Cyan
Write-Host "  ║                                      by sariamubeen ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Step 1: Create install directory ─────────────────────────────────────────

Write-Host "[1/5] Creating install directory..." -ForegroundColor Yellow
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}
Write-Host "       $InstallDir" -ForegroundColor Green

# ── Step 2: Copy scripts ────────────────────────────────────────────────────

Write-Host "[2/5] Installing scripts..." -ForegroundColor Yellow

$FilesToCopy = @("config.ps1", "Open-PDFInBrowser.ps1", "open-pdf.bat")

foreach ($File in $FilesToCopy) {
    $Source = Join-Path $ScriptDir $File
    if (-not (Test-Path $Source)) {
        Write-Host "       ERROR: $File not found in $ScriptDir" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Copy-Item -Path $Source -Destination (Join-Path $InstallDir $File) -Force
    Write-Host "       Installed $File" -ForegroundColor Green
}

# ── Step 3: Register ProgId in registry ──────────────────────────────────────

Write-Host "[3/5] Registering file handler..." -ForegroundColor Yellow

$BatchPath = Join-Path $InstallDir "open-pdf.bat"
$ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"

# Create ProgId key
New-Item -Path $ProgIdPath -Force | Out-Null
Set-ItemProperty -Path $ProgIdPath -Name "(Default)" -Value $DisplayName

# FriendlyTypeName for display
Set-ItemProperty -Path $ProgIdPath -Name "FriendlyTypeName" -Value $DisplayName

# Shell > open > command
$CommandPath = "$ProgIdPath\shell\open\command"
New-Item -Path $CommandPath -Force | Out-Null
Set-ItemProperty -Path $CommandPath -Name "(Default)" -Value "`"$BatchPath`" `"%1`""

Write-Host "       Registered ProgId: $ProgId" -ForegroundColor Green

# ── Step 4: Associate .pdf extension ────────────────────────────────────────

Write-Host "[4/5] Setting .pdf file association..." -ForegroundColor Yellow

$ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"

# Ensure the key exists
if (-not (Test-Path $ExtPath)) {
    New-Item -Path $ExtPath -Force | Out-Null
}

# Back up current handler
$CurrentHandler = (Get-ItemProperty -Path $ExtPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
if ($CurrentHandler -and $CurrentHandler -ne $ProgId) {
    Set-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -Value $CurrentHandler
    Write-Host "       Backed up previous handler: $CurrentHandler" -ForegroundColor DarkGray
}

Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value $ProgId

# Register via assoc/ftype as well (belt and suspenders)
cmd /c "ftype $ProgId=`"$BatchPath`" `"%1`"" 2>$null | Out-Null
cmd /c "assoc .pdf=$ProgId" 2>$null | Out-Null

Write-Host "       .pdf → $ProgId" -ForegroundColor Green

# ── Step 5: Refresh Windows Shell ────────────────────────────────────────────

Write-Host "[5/5] Refreshing shell..." -ForegroundColor Yellow

try {
    $ShellCode = @'
using System;
using System.Runtime.InteropServices;
public class ShellRefresh {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
    public static void Refresh() {
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero);
    }
}
'@
    Add-Type -TypeDefinition $ShellCode -Language CSharp -ErrorAction SilentlyContinue
    [ShellRefresh]::Refresh()
    Write-Host "       Shell cache refreshed" -ForegroundColor Green
}
catch {
    Write-Host "       Shell refresh skipped (non-critical)" -ForegroundColor DarkGray
}

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║  Setup Complete!                       sariamubeen  ║" -ForegroundColor Green
Write-Host "  ║                                                      ║" -ForegroundColor Green
Write-Host "  ║  Double-clicking any .pdf file will now open         ║" -ForegroundColor Green
Write-Host "  ║  the browser-based PDF editor.                       ║" -ForegroundColor Green
Write-Host "  ║                                                      ║" -ForegroundColor Green
Write-Host "  ║  Server: $PDFEditorURL" -ForegroundColor Green
Write-Host "  ║                                                      ║" -ForegroundColor Green
Write-Host "  ║  To revert: run Unregister-PDFHandler.ps1 as Admin   ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  NOTE (Windows 10/11):" -ForegroundColor DarkYellow
Write-Host "  Windows may also require manually setting the default app:" -ForegroundColor DarkYellow
Write-Host "    Settings → Apps → Default apps → search '.pdf'" -ForegroundColor DarkYellow
Write-Host "    Select '$DisplayName'" -ForegroundColor DarkYellow
Write-Host ""
Read-Host "Press Enter to close"
