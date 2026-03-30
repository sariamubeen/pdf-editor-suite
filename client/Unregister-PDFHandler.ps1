<#
.SYNOPSIS
    Reverts the .pdf file association to the previous handler.

.DESCRIPTION
    Removes the PDF Editor Suite file association and optionally
    deletes the install directory. Restores whatever handler was
    registered before PDF Editor Suite was installed.

.NOTES
    Part of PDF Editor Suite.
    Requires: Administrator privileges.
#>

# ── Require admin ────────────────────────────────────────────────────────────

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host ""
    Write-Host "ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

$ErrorActionPreference = "Stop"

# ── Load configuration ───────────────────────────────────────────────────────

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ConfigFile = Join-Path $ScriptDir "config.ps1"

# Try installed location first, then script directory
if (-not (Test-Path $ConfigFile)) {
    # Fallback: hardcoded defaults matching Register script
    $InstallDir = "$env:ProgramFiles\PDFEditorSuite"
    $ProgId = "PDFEditorSuite.PDF"
    $DisplayName = "PDF Editor Suite (Browser)"
}
else {
    . $ConfigFile
}

# ── Banner ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  PDF Editor Suite — Uninstall" -ForegroundColor Cyan
Write-Host ""

# ── Restore previous .pdf handler ────────────────────────────────────────────

$ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"

if (Test-Path $ExtPath) {
    $Previous = (Get-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue)."PDFEditorSuite_PreviousHandler"

    if ($Previous) {
        Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value $Previous
        Remove-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue
        Write-Host "  [OK] Restored previous handler: $Previous" -ForegroundColor Green
    }
    else {
        # Clear association — Windows will prompt user to pick an app
        Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value ""
        Write-Host "  [OK] Cleared .pdf association (Windows will prompt user)" -ForegroundColor Green
    }
}

# ── Remove ProgId ────────────────────────────────────────────────────────────

$ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"

if (Test-Path $ProgIdPath) {
    Remove-Item -Path $ProgIdPath -Recurse -Force
    Write-Host "  [OK] Removed ProgId: $ProgId" -ForegroundColor Green
}
else {
    Write-Host "  [--] ProgId not found (already removed)" -ForegroundColor DarkGray
}

# ── Remove ftype ─────────────────────────────────────────────────────────────

cmd /c "ftype $ProgId=" 2>$null | Out-Null
Write-Host "  [OK] Removed ftype entry" -ForegroundColor Green

# ── Refresh shell ────────────────────────────────────────────────────────────

try {
    $ShellCode = @'
using System;
using System.Runtime.InteropServices;
public class ShellRefreshUninstall {
    [DllImport("shell32.dll")]
    public static extern void SHChangeNotify(int eventId, int flags, IntPtr item1, IntPtr item2);
    public static void Refresh() {
        SHChangeNotify(0x08000000, 0x0000, IntPtr.Zero, IntPtr.Zero);
    }
}
'@
    Add-Type -TypeDefinition $ShellCode -Language CSharp -ErrorAction SilentlyContinue
    [ShellRefreshUninstall]::Refresh()
}
catch { }

Write-Host "  [OK] Shell cache refreshed" -ForegroundColor Green

# ── Optionally remove install directory ──────────────────────────────────────

if (Test-Path $InstallDir) {
    Write-Host ""
    $Remove = Read-Host "  Remove install directory ($InstallDir)? [y/N]"
    if ($Remove -eq "y") {
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-Host "  [OK] Removed $InstallDir" -ForegroundColor Green
    }
    else {
        Write-Host "  [--] Kept $InstallDir" -ForegroundColor DarkGray
    }
}

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  Uninstall complete. PDF file association has been reverted." -ForegroundColor Green
Write-Host ""
Read-Host "Press Enter to close"
