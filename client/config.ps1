# =============================================================================
# PDF Editor Suite — Client Configuration
# =============================================================================
# Edit this file ONCE before deploying to Windows machines.
# All other scripts read from this file.
# =============================================================================

# URL of your Stirling-PDF server (as configured in Nginx Proxy Manager)
# Must include https:// — no trailing slash
$PDFEditorURL = "https://pdf.example.com"

# Install directory on the Windows machine
$InstallDir = "$env:ProgramFiles\PDFEditorSuite"

# Registry ProgId (no need to change unless conflicts arise)
$ProgId = "PDFEditorSuite.PDF"

# Display name shown in Windows "Open with" and Default Apps
$DisplayName = "PDF Editor Suite (Browser)"
