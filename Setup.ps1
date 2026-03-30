<#
.SYNOPSIS
    One-click setup for PDF Editor Suite on Windows.

.DESCRIPTION
    This script auto-detects the environment and does everything:
      1. Prompts for (or auto-discovers) the server IP/URL
      2. Tests server connectivity
      3. Detects if the server requires login
      4. Writes config.ps1 with the correct settings
      5. Installs scripts and registers the .pdf file association
      6. Validates the installation

    Run as Administrator for full setup.

.PARAMETER ServerURL
    Server URL (e.g., http://192.168.1.50:8080). If not provided, the script
    will scan the local network to find Stirling-PDF or prompt you.

.PARAMETER Username
    Stirling-PDF username (only needed if server has login enabled).

.PARAMETER Password
    Stirling-PDF password (only needed if server has login enabled).

.PARAMETER Uninstall
    Remove PDF Editor Suite from this machine.

.EXAMPLE
    # Auto-discover server on the network
    .\Setup.ps1

    # Specify server directly
    .\Setup.ps1 -ServerURL "http://192.168.1.50:8080"

    # Server with authentication
    .\Setup.ps1 -ServerURL "http://192.168.1.50:8080" -Username admin -Password MyPass123

    # Uninstall
    .\Setup.ps1 -Uninstall

.NOTES
    PDF Editor Suite by sariamubeen
#>

param(
    [string]$ServerURL = "",
    [string]$Username = "",
    [string]$Password = "",
    [switch]$Uninstall
)

$ErrorActionPreference = "Stop"

# ── Constants ────────────────────────────────────────────────────────────────

$ProgId       = "PDFEditorSuite.PDF"
$DisplayName  = "PDF Editor Suite (Browser)"
$InstallDir   = "$env:ProgramFiles\PDFEditorSuite"
$ScriptDir    = Split-Path -Parent $MyInvocation.MyCommand.Definition
$ClientDir    = Join-Path $ScriptDir "client"

# ── Require admin ────────────────────────────────────────────────────────────

$IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)

if (-not $IsAdmin) {
    Write-Host ""
    Write-Host "  ERROR: This script must be run as Administrator." -ForegroundColor Red
    Write-Host ""
    Write-Host "  Right-click Setup.ps1 and select 'Run with PowerShell as Administrator'." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ── Banner ───────────────────────────────────────────────────────────────────

Write-Host ""
Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║  PDF Editor Suite — One-Click Setup                      ║" -ForegroundColor Cyan
Write-Host "  ║                                          by sariamubeen ║" -ForegroundColor Cyan
Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# ── Uninstall mode ───────────────────────────────────────────────────────────

if ($Uninstall) {
    Write-Host "  Uninstalling PDF Editor Suite..." -ForegroundColor Yellow
    Write-Host ""

    # Restore previous handler
    $ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"
    if (Test-Path $ExtPath) {
        $Previous = (Get-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue)."PDFEditorSuite_PreviousHandler"
        if ($Previous) {
            Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value $Previous
            Remove-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -ErrorAction SilentlyContinue
            Write-Host "  [OK] Restored previous handler: $Previous" -ForegroundColor Green
        } else {
            Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value ""
            Write-Host "  [OK] Cleared .pdf association" -ForegroundColor Green
        }
    }

    # Remove ProgId
    $ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"
    if (Test-Path $ProgIdPath) {
        Remove-Item -Path $ProgIdPath -Recurse -Force
        Write-Host "  [OK] Removed ProgId" -ForegroundColor Green
    }

    cmd /c "ftype $ProgId=" 2>$null | Out-Null

    # Remove install directory
    if (Test-Path $InstallDir) {
        Remove-Item -Path $InstallDir -Recurse -Force
        Write-Host "  [OK] Removed $InstallDir" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "  Uninstall complete." -ForegroundColor Green
    Write-Host ""
    Read-Host "Press Enter to close"
    exit 0
}

# ── Verify client folder exists ──────────────────────────────────────────────

if (-not (Test-Path $ClientDir)) {
    Write-Host "  ERROR: client/ folder not found at $ClientDir" -ForegroundColor Red
    Write-Host "  Make sure you're running Setup.ps1 from the pdf-editor-suite root." -ForegroundColor Yellow
    Write-Host ""
    Read-Host "Press Enter to exit"
    exit 1
}

# ══════════════════════════════════════════════════════════════════════════════
# STEP 1: Find the server
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "  [1/6] Finding Stirling-PDF server..." -ForegroundColor Yellow

if ($ServerURL -eq "") {
    # Try auto-discovery: scan common ports on the local subnet
    Write-Host "         Scanning local network for Stirling-PDF..." -ForegroundColor DarkGray

    $LocalIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.InterfaceAlias -notmatch "Loopback" -and $_.IPAddress -notmatch "^169\."
    } | Select-Object -First 1).IPAddress

    $Subnet = ($LocalIP -split '\.')[0..2] -join '.'
    $FoundServer = $null
    $PortsToTry = @(8080, 80, 443, 8443, 8888)

    # Scan .1 through .254 on the subnet with common ports
    $ScanResults = @()
    foreach ($Port in $PortsToTry) {
        foreach ($i in 1..254) {
            $TestIP = "$Subnet.$i"
            if ($TestIP -eq $LocalIP) { continue }

            try {
                $TcpClient = New-Object System.Net.Sockets.TcpClient
                $AsyncResult = $TcpClient.BeginConnect($TestIP, $Port, $null, $null)
                $Wait = $AsyncResult.AsyncWaitHandle.WaitOne(150)  # 150ms timeout per host
                if ($Wait -and $TcpClient.Connected) {
                    $TcpClient.EndConnect($AsyncResult)
                    $TcpClient.Close()

                    # Verify it's actually Stirling-PDF
                    $Protocol = if ($Port -eq 443 -or $Port -eq 8443) { "https" } else { "http" }
                    $TestURL = "${Protocol}://${TestIP}:${Port}"
                    try {
                        $Response = Invoke-WebRequest -Uri "$TestURL/api/v1/info/status" `
                            -UseBasicParsing -TimeoutSec 3 -ErrorAction Stop
                        if ($Response.StatusCode -eq 200) {
                            $ScanResults += $TestURL
                            Write-Host "         Found: $TestURL" -ForegroundColor Green
                        }
                    }
                    catch {
                        # Check if it's a redirect to login (still Stirling-PDF)
                        $StatusCode = $_.Exception.Response.StatusCode.value__
                        if ($StatusCode -eq 302 -or $StatusCode -eq 401 -or $StatusCode -eq 200) {
                            $ScanResults += $TestURL
                            Write-Host "         Found: $TestURL (requires login)" -ForegroundColor Green
                        }
                    }
                } else {
                    $TcpClient.Close()
                }
            }
            catch {
                # Host not reachable — skip
            }
        }

        if ($ScanResults.Count -gt 0) { break }  # Stop after finding on first port
    }

    if ($ScanResults.Count -eq 1) {
        $ServerURL = $ScanResults[0]
        Write-Host "         Auto-detected server: $ServerURL" -ForegroundColor Green
    }
    elseif ($ScanResults.Count -gt 1) {
        Write-Host ""
        Write-Host "         Multiple servers found:" -ForegroundColor Yellow
        for ($i = 0; $i -lt $ScanResults.Count; $i++) {
            Write-Host "           [$($i+1)] $($ScanResults[$i])" -ForegroundColor White
        }
        $Choice = Read-Host "         Enter number (1-$($ScanResults.Count))"
        $ServerURL = $ScanResults[[int]$Choice - 1]
    }
    else {
        Write-Host "         No Stirling-PDF server found on the local network." -ForegroundColor Yellow
        Write-Host ""
        $ServerURL = Read-Host "         Enter your server URL (e.g., http://192.168.1.50:8080)"
    }
}

if ($ServerURL -eq "" -or $ServerURL -match "YOUR_SERVER_IP") {
    Write-Host "  ERROR: No server URL provided." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

# Remove trailing slash
$ServerURL = $ServerURL.TrimEnd('/')

Write-Host "         Server: $ServerURL" -ForegroundColor Green
Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 2: Test connectivity
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "  [2/6] Testing server connectivity..." -ForegroundColor Yellow

$ServerReachable = $false
$LoginRequired = $false

try {
    $Response = Invoke-WebRequest -Uri "$ServerURL/api/v1/info/status" `
        -UseBasicParsing -TimeoutSec 10 -ErrorAction Stop

    if ($Response.StatusCode -eq 200) {
        $ServerReachable = $true
        Write-Host "         Server is online (no login required)" -ForegroundColor Green
    }
}
catch {
    $StatusCode = $_.Exception.Response.StatusCode.value__
    if ($StatusCode -eq 302 -or $StatusCode -eq 401 -or $StatusCode -eq 403) {
        $ServerReachable = $true
        $LoginRequired = $true
        Write-Host "         Server is online (login required)" -ForegroundColor Green
    }
    else {
        Write-Host "         Cannot reach server: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host ""
        Write-Host "  Check that:" -ForegroundColor Yellow
        Write-Host "    - The server is running (docker compose up -d)" -ForegroundColor Yellow
        Write-Host "    - The firewall allows port access" -ForegroundColor Yellow
        Write-Host "    - The IP address is correct" -ForegroundColor Yellow
        Write-Host ""
        $Continue = Read-Host "  Continue anyway? (y/N)"
        if ($Continue -ne "y") { exit 1 }
        $ServerReachable = $true  # User chose to continue
    }
}

Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 3: Handle credentials (if login required)
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "  [3/6] Configuring authentication..." -ForegroundColor Yellow

if ($LoginRequired) {
    if ($Username -eq "") {
        Write-Host "         The server requires login." -ForegroundColor Yellow
        Write-Host "         Enter credentials so PDFs open without prompting." -ForegroundColor DarkGray
        Write-Host ""
        $Username = Read-Host "         Username"
        $SecurePass = Read-Host "         Password" -AsSecureString
        $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecurePass)
        $Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
    }

    # Test login
    try {
        $LoginBody = @{ username = $Username; password = $Password }
        $TestSession = New-Object Microsoft.PowerShell.Commands.WebRequestSession
        Invoke-WebRequest -Uri "$ServerURL/login" -Method POST -Body $LoginBody `
            -WebSession $TestSession -UseBasicParsing -MaximumRedirection 5 `
            -TimeoutSec 10 -ErrorAction Stop | Out-Null
        Write-Host "         Login successful — credentials verified" -ForegroundColor Green
    }
    catch {
        Write-Host "         WARNING: Login test failed — check credentials" -ForegroundColor Yellow
        Write-Host "         ($($_.Exception.Message))" -ForegroundColor DarkGray
    }
}
else {
    Write-Host "         No login required — PDFs will open directly" -ForegroundColor Green
}

Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 4: Write config and install files
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "  [4/6] Installing files..." -ForegroundColor Yellow

# Create install directory
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

# Generate config.ps1 with detected settings
$ConfigContent = @"
# =============================================================================
# PDF Editor Suite — Client Configuration (auto-generated by Setup.ps1)
# =============================================================================

`$PDFEditorURL = "$ServerURL"

`$RequireLogin = `$$($LoginRequired.ToString().ToLower())

`$StirlingUsername = "$Username"
`$StirlingPassword = "$Password"

`$InstallDir = "`$env:ProgramFiles\PDFEditorSuite"

`$ProgId = "$ProgId"

`$DisplayName = "$DisplayName"
"@

Set-Content -Path (Join-Path $InstallDir "config.ps1") -Value $ConfigContent -Encoding UTF8
Write-Host "         Generated config.ps1 with server: $ServerURL" -ForegroundColor Green

# Copy other scripts
$FilesToCopy = @("Open-PDFInBrowser.ps1", "open-pdf.bat")
foreach ($File in $FilesToCopy) {
    $Source = Join-Path $ClientDir $File
    if (Test-Path $Source) {
        Copy-Item -Path $Source -Destination (Join-Path $InstallDir $File) -Force
        Write-Host "         Installed $File" -ForegroundColor Green
    }
    else {
        Write-Host "         WARNING: $File not found in client/" -ForegroundColor Yellow
    }
}

Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 5: Register file association
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "  [5/6] Registering .pdf file association..." -ForegroundColor Yellow

$BatchPath = Join-Path $InstallDir "open-pdf.bat"
$ProgIdPath = "HKLM:\SOFTWARE\Classes\$ProgId"

# Create ProgId
New-Item -Path $ProgIdPath -Force | Out-Null
Set-ItemProperty -Path $ProgIdPath -Name "(Default)" -Value $DisplayName
Set-ItemProperty -Path $ProgIdPath -Name "FriendlyTypeName" -Value $DisplayName

$CommandPath = "$ProgIdPath\shell\open\command"
New-Item -Path $CommandPath -Force | Out-Null
Set-ItemProperty -Path $CommandPath -Name "(Default)" -Value "`"$BatchPath`" `"%1`""

Write-Host "         Registered ProgId: $ProgId" -ForegroundColor Green

# Set .pdf association
$ExtPath = "HKLM:\SOFTWARE\Classes\.pdf"
if (-not (Test-Path $ExtPath)) {
    New-Item -Path $ExtPath -Force | Out-Null
}

$CurrentHandler = (Get-ItemProperty -Path $ExtPath -Name "(Default)" -ErrorAction SilentlyContinue)."(Default)"
if ($CurrentHandler -and $CurrentHandler -ne $ProgId) {
    Set-ItemProperty -Path $ExtPath -Name "PDFEditorSuite_PreviousHandler" -Value $CurrentHandler
    Write-Host "         Backed up previous handler: $CurrentHandler" -ForegroundColor DarkGray
}

Set-ItemProperty -Path $ExtPath -Name "(Default)" -Value $ProgId
cmd /c "ftype $ProgId=`"$BatchPath`" `"%1`"" 2>$null | Out-Null
cmd /c "assoc .pdf=$ProgId" 2>$null | Out-Null

Write-Host "         .pdf → $ProgId" -ForegroundColor Green

# Refresh shell
try {
    Add-Type -TypeDefinition @'
using System; using System.Runtime.InteropServices;
public class SR3 { [DllImport("shell32.dll")] public static extern void SHChangeNotify(int e, int f, IntPtr i1, IntPtr i2);
    public static void R() { SHChangeNotify(0x08000000, 0, IntPtr.Zero, IntPtr.Zero); } }
'@ -ErrorAction SilentlyContinue
    [SR3]::R()
} catch { }

Write-Host ""

# ══════════════════════════════════════════════════════════════════════════════
# STEP 6: Validate
# ══════════════════════════════════════════════════════════════════════════════

Write-Host "  [6/6] Validating installation..." -ForegroundColor Yellow

$AllGood = $true

# Check files
foreach ($File in @("config.ps1", "Open-PDFInBrowser.ps1", "open-pdf.bat")) {
    if (Test-Path (Join-Path $InstallDir $File)) {
        Write-Host "         [OK] $File" -ForegroundColor Green
    } else {
        Write-Host "         [!!] $File missing" -ForegroundColor Red
        $AllGood = $false
    }
}

# Check registry
if (Test-Path "HKLM:\SOFTWARE\Classes\$ProgId") {
    Write-Host "         [OK] Registry handler" -ForegroundColor Green
} else {
    Write-Host "         [!!] Registry handler missing" -ForegroundColor Red
    $AllGood = $false
}

# Check server
if ($ServerReachable) {
    Write-Host "         [OK] Server reachable" -ForegroundColor Green
} else {
    Write-Host "         [!!] Server not reachable" -ForegroundColor Red
    $AllGood = $false
}

Write-Host ""

# ── Done ─────────────────────────────────────────────────────────────────────

if ($AllGood) {
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Green
    Write-Host "  ║  Setup Complete!                          sariamubeen   ║" -ForegroundColor Green
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ║  Double-click any .pdf file to open it in the browser.   ║" -ForegroundColor Green
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ║  Server : $ServerURL" -ForegroundColor Green
    if ($LoginRequired) {
        Write-Host "  ║  Auth   : Auto-login enabled (no prompts)" -ForegroundColor Green
    } else {
        Write-Host "  ║  Auth   : No login required" -ForegroundColor Green
    }
    Write-Host "  ║                                                          ║" -ForegroundColor Green
    Write-Host "  ║  To uninstall: .\Setup.ps1 -Uninstall                    ║" -ForegroundColor Green
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Green
} else {
    Write-Host "  ╔══════════════════════════════════════════════════════════╗" -ForegroundColor Yellow
    Write-Host "  ║  Setup finished with warnings — review output above.     ║" -ForegroundColor Yellow
    Write-Host "  ╚══════════════════════════════════════════════════════════╝" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "  NOTE (Windows 10/11):" -ForegroundColor DarkYellow
Write-Host "  You may also need to set the default app manually:" -ForegroundColor DarkYellow
Write-Host "    Settings > Apps > Default apps > search '.pdf'" -ForegroundColor DarkYellow
Write-Host "    Select '$DisplayName'" -ForegroundColor DarkYellow
Write-Host ""
Read-Host "Press Enter to close"
