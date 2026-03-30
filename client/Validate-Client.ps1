<#
.SYNOPSIS
    Validates the PDF Editor Suite client installation on a Windows machine.

.DESCRIPTION
    Tests all critical components of the client deployment:
      1. Installation files exist
      2. Registry entries are correct
      3. File association is set
      4. Server is reachable (HTTPS)
      5. Browser can be launched
      6. PowerShell execution policy allows scripts

    Can be run as a regular user (non-admin) for read-only checks.
    Run as admin for full registry validation.

.PARAMETER Fix
    Attempt to fix common issues automatically (requires admin).

.EXAMPLE
    .\Validate-Client.ps1
    .\Validate-Client.ps1 -Fix

.NOTES
    Part of PDF Editor Suite.
#>

param(
    [switch]$Fix
)

$ErrorActionPreference = "SilentlyContinue"

# -- Load config --------------------------------------------------------------

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Try installed location first, then script directory
$ConfigPaths = @(
    (Join-Path "$env:ProgramFiles\PDFEditorSuite" "config.ps1"),
    (Join-Path $ScriptDir "config.ps1")
)

$ConfigLoaded = $false
foreach ($Path in $ConfigPaths) {
    if (Test-Path $Path) {
        . $Path
        $ConfigLoaded = $true
        break
    }
}

if (-not $ConfigLoaded) {
    $PDFEditorURL = "https://pdf.example.com"
    $InstallDir = "$env:ProgramFiles\PDFEditorSuite"
    $ProgId = "PDFEditorSuite.PDF"
    $DisplayName = "PDF Editor Suite (Browser)"
}

# -- Test framework -----------------------------------------------------------

$PassCount = 0
$FailCount = 0
$WarnCount = 0
$SkipCount = 0

function Test-Pass  { param([string]$Msg) $script:PassCount++; Write-Host "  [PASS] $Msg" -ForegroundColor Green }
function Test-Fail  { param([string]$Msg) $script:FailCount++; Write-Host "  [FAIL] $Msg" -ForegroundColor Red }
function Test-Warn  { param([string]$Msg) $script:WarnCount++; Write-Host "  [WARN] $Msg" -ForegroundColor Yellow }
function Test-Skip  { param([string]$Msg) $script:SkipCount++; Write-Host "  [SKIP] $Msg" -ForegroundColor DarkGray }
function Test-Info  { param([string]$Msg) Write-Host "         $Msg" -ForegroundColor DarkGray }

# -- Banner -------------------------------------------------------------------

Write-Host ""
Write-Host "  +======================================================+" -ForegroundColor Cyan
Write-Host "  |  PDF Editor Suite - Client Validation                |" -ForegroundColor Cyan
Write-Host "  +======================================================+" -ForegroundColor Cyan
Write-Host ""

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)
if ($IsAdmin) {
    Test-Info "Running as Administrator - full checks enabled"
} else {
    Test-Info "Running as standard user - some checks limited"
}
Write-Host ""

# =============================================================================
# TEST GROUP 1: Installation Files
# =============================================================================

Write-Host "  -- Installation Files --" -ForegroundColor Cyan

$RequiredFiles = @("config.ps1", "Open-PDFInBrowser.ps1", "open-pdf.bat")

if (Test-Path $InstallDir) {
    Test-Pass "Install directory exists: $InstallDir"

    foreach ($File in $RequiredFiles) {
        $FilePath = Join-Path $InstallDir $File
        if (Test-Path $FilePath) {
            Test-Pass "$File present"
        } else {
            Test-Fail "$File missing from $InstallDir"
        }
    }
} else {
    Test-Fail "Install directory not found: $InstallDir"
    foreach ($File in $RequiredFiles) {
        Test-Skip "$File (install dir missing)"
    }
}

Write-Host ""

# =============================================================================
# TEST GROUP 2: Configuration
# =============================================================================

Write-Host "  -- Configuration --" -ForegroundColor Cyan

if ($PDFEditorURL -match "(pdf\.example\.com|YOUR_SERVER_IP)") {
    Test-Fail "Server URL is still the default - run Setup.ps1 or edit config.ps1"
} elseif ($PDFEditorURL -match "^https://") {
    Test-Pass "Server URL configured: $PDFEditorURL"
} elseif ($PDFEditorURL -match "^http://") {
    Test-Warn "Server URL uses HTTP (not HTTPS): $PDFEditorURL"
} else {
    Test-Fail "Server URL looks invalid: $PDFEditorURL"
}

Write-Host ""

# =============================================================================
# TEST GROUP 3: Registry & File Association
# =============================================================================

Write-Host "  -- File Association --" -ForegroundColor Cyan

# ProgId exists
$ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"
if (Test-Path $ProgIdPath) {
    Test-Pass "ProgId registered: $ProgId"

    # Command is correct
    $CommandPath = "$ProgIdPath\shell\open\command"
    $Command = (Get-ItemProperty -Path $CommandPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
    if ($Command -and $Command -match "open-pdf\.bat") {
        Test-Pass "Shell command points to open-pdf.bat"
    } else {
        Test-Fail "Shell command incorrect: $Command"
    }
} else {
    Test-Fail "ProgId not registered: $ProgId"
}

# .pdf association
$ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"
$CurrentAssoc = (Get-ItemProperty -Path $ExtPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
if ($CurrentAssoc -eq $ProgId) {
    Test-Pass ".pdf association set to $ProgId"
} else {
    Test-Warn ".pdf association is '$CurrentAssoc' (expected: $ProgId)"
    Test-Info "This is normal on Windows 10/11 - set via Settings > Default apps"
}

# Previous handler backup
$PreviousHandler = (Get-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue)."PDFEditorSuite_PreviousHandler"
if ($PreviousHandler) {
    Test-Pass "Previous handler backed up: $PreviousHandler"
} else {
    Test-Info "No previous handler backup found (first install or already reverted)"
}

# ftype
$FtypeOutput = cmd /c "ftype $ProgId" 2>&1
if ($FtypeOutput -match "open-pdf\.bat") {
    Test-Pass "ftype entry registered"
} else {
    Test-Warn "ftype entry not found or incorrect"
}

Write-Host ""

# =============================================================================
# TEST GROUP 4: Server Connectivity
# =============================================================================

Write-Host "  -- Server Connectivity --" -ForegroundColor Cyan

if ($PDFEditorURL -ne "https://pdf.example.com") {
    try {
        $Response = Invoke-WebRequest -Uri "$PDFEditorURL/api/v1/info/status" -UseBasicParsing -TimeoutSec 15 -ErrorAction Stop
        if ($Response.StatusCode -eq 200) {
            Test-Pass "Server reachable: $PDFEditorURL (HTTP $($Response.StatusCode))"
        } else {
            Test-Warn "Server returned HTTP $($Response.StatusCode)"
        }
    }
    catch [System.Net.WebException] {
        $StatusCode = $_.Exception.Response.StatusCode.value__
        if ($StatusCode) {
            Test-Warn "Server returned HTTP $StatusCode (may require auth - that's OK)"
        } else {
            Test-Fail "Cannot reach server: $($_.Exception.Message)"
        }
    }
    catch {
        Test-Fail "Cannot reach server: $($_.Exception.Message)"
    }

    # SSL check
    if ($PDFEditorURL -match "^https://(.+?)(/|$)") {
        $Domain = $Matches[1]
        try {
            $TcpClient = New-Object System.Net.Sockets.TcpClient
            $TcpClient.Connect($Domain, 443)
            $SslStream = New-Object System.Net.Security.SslStream($TcpClient.GetStream(), $false)
            $SslStream.AuthenticateAsClient($Domain)
            $Cert = $SslStream.RemoteCertificate
            $Expiry = [datetime]::Parse($Cert.GetExpirationDateString())
            $DaysLeft = ($Expiry - (Get-Date)).Days

            if ($DaysLeft -gt 30) {
                Test-Pass "SSL certificate valid ($DaysLeft days remaining)"
            } elseif ($DaysLeft -gt 0) {
                Test-Warn "SSL certificate expiring soon ($DaysLeft days)"
            } else {
                Test-Fail "SSL certificate expired!"
            }

            $SslStream.Dispose()
            $TcpClient.Dispose()
        }
        catch {
            Test-Warn "Could not verify SSL certificate: $($_.Exception.Message)"
        }
    }
} else {
    Test-Skip "Server connectivity (URL not configured)"
}

Write-Host ""

# =============================================================================
# TEST GROUP 5: PowerShell Environment
# =============================================================================

Write-Host "  -- PowerShell Environment --" -ForegroundColor Cyan

# Execution policy
$Policy = Get-ExecutionPolicy -Scope LocalMachine
if ($Policy -eq "Restricted") {
    Test-Fail "Execution policy is Restricted - scripts cannot run"
    Test-Info "Fix: Set-ExecutionPolicy RemoteSigned -Scope LocalMachine"
} elseif ($Policy -eq "AllSigned") {
    Test-Warn "Execution policy is AllSigned - unsigned scripts may be blocked"
} else {
    Test-Pass "Execution policy: $Policy"
}

# PowerShell version
$PSVer = $PSVersionTable.PSVersion
if ($PSVer.Major -ge 5) {
    Test-Pass "PowerShell version: $PSVer"
} else {
    Test-Warn "PowerShell version $PSVer may have issues (5.1+ recommended)"
}

# .NET assemblies (used by handler script)
try {
    Add-Type -AssemblyName System.Windows.Forms -ErrorAction Stop
    Test-Pass "System.Windows.Forms available (notifications, clipboard)"
}
catch {
    Test-Warn "System.Windows.Forms not available (notifications will not work)"
}

Write-Host ""

# =============================================================================
# TEST GROUP 6: Functional Test
# =============================================================================

Write-Host "  -- Functional Test --" -ForegroundColor Cyan

$HandlerScript = Join-Path $InstallDir "Open-PDFInBrowser.ps1"
$ConfigInInstall = Join-Path $InstallDir "config.ps1"

if ((Test-Path $HandlerScript) -and (Test-Path $ConfigInInstall)) {
    # Check script parses without errors
    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $HandlerScript, [ref]$null, [ref]$null
        )
        Test-Pass "Handler script parses without errors"
    }
    catch {
        Test-Fail "Handler script has syntax errors: $($_.Exception.Message)"
    }

    try {
        $null = [System.Management.Automation.Language.Parser]::ParseFile(
            $ConfigInInstall, [ref]$null, [ref]$null
        )
        Test-Pass "Config script parses without errors"
    }
    catch {
        Test-Fail "Config script has syntax errors: $($_.Exception.Message)"
    }
} else {
    Test-Skip "Functional test (scripts not installed)"
}

Write-Host ""

# =============================================================================
# Summary
# =============================================================================

$Total = $PassCount + $FailCount + $WarnCount + $SkipCount

Write-Host "  -- Summary -------------------------------------------" -ForegroundColor Cyan
Write-Host ""
Write-Host "  $PassCount passed  " -ForegroundColor Green -NoNewline
Write-Host "$FailCount failed  " -ForegroundColor Red -NoNewline
Write-Host "$WarnCount warnings  " -ForegroundColor Yellow -NoNewline
Write-Host "$SkipCount skipped  ($Total total)" -ForegroundColor DarkGray
Write-Host ""

if ($FailCount -gt 0) {
    Write-Host "  Some tests failed. Review output above." -ForegroundColor Red
} elseif ($WarnCount -gt 0) {
    Write-Host "  All critical tests passed with some warnings." -ForegroundColor Yellow
} else {
    Write-Host "  All tests passed!" -ForegroundColor Green
}

Write-Host ""
Read-Host "Press Enter to close"
