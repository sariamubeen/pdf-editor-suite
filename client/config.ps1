# =============================================================================
# PDF Editor Suite — Client Configuration
# =============================================================================
# Edit this file ONCE before deploying to Windows machines.
# All other scripts read from this file.
# =============================================================================

# URL of your Stirling-PDF server
# Use your server's private IP + port, or domain if behind a reverse proxy
# No trailing slash
# Examples:
#   $PDFEditorURL = "http://192.168.1.50:8080"
#   $PDFEditorURL = "https://pdf.yourdomain.com"
$PDFEditorURL = "http://YOUR_SERVER_IP:8080"

# Authentication — set to $true if your server requires login
# If $false, PDFs open directly without any login prompt
$RequireLogin = $false

# Credentials for auto-login (only used when $RequireLogin = $true)
# The script will authenticate automatically so the user never sees a login page
$StirlingUsername = "admin"
$StirlingPassword = "ChangeMeOnFirstLogin!"

# Install directory on the Windows machine
$InstallDir = "$env:ProgramFiles\PDFEditorSuite"

# Registry ProgId (no need to change unless conflicts arise)
$ProgId = "PDFEditorSuite.PDF"

# Display name shown in Windows "Open with" and Default Apps
$DisplayName = "PDF Editor Suite (Browser)"
