<#
.SYNOPSIS
    Deploys PDF Editor Suite to domain-joined machines via Group Policy.

.DESCRIPTION
    This script is designed to be run as a GPO Startup Script or via
    SCCM/Intune. It silently installs the PDF Editor Suite file handler
    on the machine without user interaction.

    It is idempotent — safe to run multiple times (skips if already installed).

.PARAMETER ServerURL
    Override the server URL from config.ps1. Useful when deploying via GPO
    with different URLs for different OUs.

.PARAMETER Force
    Reinstall even if already installed.

.PARAMETER Uninstall
    Remove PDF Editor Suite from the machine.

.EXAMPLE
    # GPO Startup Script — install with default config
    Deploy-PDFEditorSuite.ps1

    # GPO with custom URL
    Deploy-PDFEditorSuite.ps1 -ServerURL "https://pdf.branch-office.com"

    # Uninstall via GPO
    Deploy-PDFEditorSuite.ps1 -Uninstall

.NOTES
    Part of PDF Editor Suite by sariamubeen.
    Runs as SYSTEM under GPO — no user interaction.
    Logs to Windows Event Log: Application → PDFEditorSuite
#>

param(
    [string]$ServerURL = "",
    [switch]$Force,
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# ── Constants ────────────────────────────────────────────────────────────────

$ProgId       = "PDFEditorSuite.PDF"
$DisplayName  = "PDF Editor Suite (Browser)"
$InstallDir   = "$env:ProgramFiles\PDFEditorSuite"
$EventSource  = "PDFEditorSuite"
$LogName      = "Application"

# ── Logging ──────────────────────────────────────────────────────────────────

function Initialize-EventLog {
    try {
        if (-not [System.Diagnostics.EventLog]::SourceExists($EventSource)) {
            [System.Diagnostics.EventLog]::CreateEventSource($EventSource, $LogName)
        }
    }
    catch {
        # Non-fatal — fall back to console only
    }
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )

    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $Prefix = switch ($Level) {
        "Info"    { "[INFO]" }
        "Warning" { "[WARN]" }
        "Error"   { "[ERR!]" }
    }

    Write-Host "$Timestamp $Prefix $Message"

    try {
        $EventType = switch ($Level) {
            "Info"    { [System.Diagnostics.EventLogEntryType]::Information }
            "Warning" { [System.Diagnostics.EventLogEntryType]::Warning }
            "Error"   { [System.Diagnostics.EventLogEntryType]::Error }
        }
        Write-EventLog -LogName $LogName -Source $EventSource -EventId 1000 -EntryType $EventType -Message $Message
    }
    catch { }
}

Initialize-EventLog

# ── Uninstall Mode ───────────────────────────────────────────────────────────

if ($Uninstall) {
    Write-Log "Starting uninstall..."

    # Restore previous .pdf handler
    $ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"
    if (Test-Path $ExtPath) {
        $Previous = (Get-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue)."PDFEditorSuite_PreviousHandler"
        if ($Previous) {
            Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value $Previous
            Remove-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue
            Write-Log "Restored previous handler: $Previous"
        }
        else {
            Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value ""
            Write-Log "Cleared .pdf association"
        }
    }

    # Remove ProgId
    $ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"
    if (Test-Path $ProgIdPath) {
        Remove-Item -Path $ProgIdPath -Recurse -Force
        Write-Log "Removed ProgId"
    }

    # Remove ftype
    cmd /c "ftype $ProgId=" 2>$null | Out-Null

    # Remove install directory
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-Log "Removed install directory"
    }

    # Refresh shell
    try {
        Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public class SR1 { [DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, IntPtr i1, IntPtr i2);
    public static void R() { SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero); } }
'@ -ErrorAction SilentlyContinue
        [SR1]::R()
    } catch { }

    Write-Log "Uninstall complete"
    exit 0
}

# ── Install Mode ─────────────────────────────────────────────────────────────

# Check if already installed
$AlreadyInstalled = (Test-Path $InstallDir) -and (Test-Path (Join-Path $InstallDir "open-pdf.bat"))

if ($AlreadyInstalled -and -not $Force) {
    Write-Log "Already installed at $InstallDir — skipping (use -Force to reinstall)"
    exit 0
}

Write-Log "Starting deployment..."

# ── Locate source files ─────────────────────────────────────────────────────

# Source can be: same directory as this script, or a network share specified via GPO
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$SourceFiles = @("config.ps1", "Open-PDFInBrowser.ps1", "open-pdf.bat")

foreach ($File in $SourceFiles) {
    $Path = Join-Path $ScriptDir $File
    if (-not (Test-Path $Path)) {
        Write-Log "Missing source file: $Path" -Level Error
        exit 1
    }
}

# ── Create install directory ─────────────────────────────────────────────────

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# ── Copy files ───────────────────────────────────────────────────────────────

foreach ($File in $SourceFiles) {
    Copy-Item -Path (Join-Path $ScriptDir $File) -Destination (Join-Path $InstallDir $File) -Force
}
Write-Log "Copied scripts to $InstallDir"

# ── Override server URL if specified ─────────────────────────────────────────

if ($ServerURL -ne "") {
    $ConfigPath = Join-Path $InstallDir "config.ps1"
    $ConfigContent = Get-Content $ConfigPath -Raw
    $ConfigContent = $ConfigContent -replace '\$PDFEditorURL\s*=\s*"[^"]*"', "`$PDFEditorURL = `"$ServerURL`""
    Set-Content -Path $ConfigPath -Value $ConfigContent -Encoding UTF8
    Write-Log "Set server URL to $ServerURL"
}

# ── Register file association ────────────────────────────────────────────────

$BatchPath = Join-Path $InstallDir "open-pdf.bat"
$ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"

New-Item -Path $ProgIdPath -Force | Out-Null
Set-ItemProperty -Path $ProgIdPath -Name "(Default)" -Value $DisplayName
Set-ItemProperty -Path $ProgIdPath -Name "FriendlyTypeName" -Value $DisplayName

$CommandPath = "$ProgIdPath\shell\open\command"
New-Item -Path $CommandPath -Force | Out-Null
Set-ItemProperty -Path $CommandPath -Name "(Default)" -Value "`"$BatchPath`" `"%1`""

Write-Log "Registered ProgId: $ProgId"

# ── Set .pdf association ─────────────────────────────────────────────────────

$ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"
if (-not (Test-Path $ExtPath)) {
    New-Item -Path $ExtPath -Force | Out-Null
}

$CurrentHandler = (Get-ItemProperty -Path $ExtPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
if ($CurrentHandler -and $CurrentHandler -ne $ProgId) {
    Set-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -Value $CurrentHandler
    Write-Log "Backed up previous handler: $CurrentHandler"
}

Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value $ProgId

cmd /c "ftype $ProgId=`"$BatchPath`" `"%1`"" 2>$null | Out-Null
cmd /c "assoc .pdf=$ProgId" 2>$null | Out-Null

Write-Log "Set .pdf → $ProgId"

# ── Refresh shell ────────────────────────────────────────────────────────────

try {
    Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public class SR2 { [DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, IntPtr i1, IntPtr i2);
    public static void R() { SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero); } }
'@ -ErrorAction SilentlyContinue
    [SR2]::R()
} catch { }

# ── Generate Default App Associations XML ────────────────────────────────────

$AssocXML = Join-Path $InstallDir "DefaultAssociations.xml"
$XMLContent = @"
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".pdf" ProgId="$ProgId" ApplicationName="$DisplayName" />
</DefaultAssociations>
"@
Set-Content -Path $AssocXML -Value $XMLContent -Encoding UTF8
Write-Log "Generated DefaultAssociations.xml at $AssocXML"

# ── Done ─────────────────────────────────────────────────────────────────────

Write-Log "Deployment complete — installed to $InstallDir"
exit 0
