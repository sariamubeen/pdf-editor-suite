# Windows Client Setup Guide

## Prerequisites

- Windows 10, Windows 11, or Windows Server 2019/2022/2025
- A modern browser (Chrome, Edge, Firefox)
- Network access to the Stirling-PDF server (HTTPS)

---

## Step 1: Configure

Edit `client/config.ps1` and set your server URL:

```powershell
$PDFEditorURL = "https://pdf.yourdomain.com"
```

This is the **only file** you need to edit.

---

## Step 2: Install

1. Copy the entire `client/` folder to the Windows machine
2. Right-click `Register-PDFHandler.ps1`
3. Select **Run with PowerShell**
4. When prompted by UAC, click **Yes** (Admin required)

The script will:
- Copy handler scripts to `C:\Program Files\PDFEditorSuite\`
- Register the `.pdf` file association in Windows Registry
- Back up the previous PDF handler for clean uninstall

---

## Step 3: Set Default App (Windows 10/11)

Windows 10/11 protects default app associations. After running the
register script, you may need to manually confirm:

1. Open **Settings → Apps → Default apps**
2. Search for `.pdf`
3. Click the current app and select **PDF Editor Suite (Browser)**

### For Domain-Joined Machines (GPO)

Create a default associations XML:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<DefaultAssociations>
  <Association Identifier=".pdf" ProgId="PDFEditorSuite.PDF" ApplicationName="PDF Editor Suite (Browser)" />
</DefaultAssociations>
```

Deploy via:
- `Computer Configuration → Admin Templates → Windows Components → File Explorer`
- **Set a default associations configuration file**

---

## User Workflow

After setup, the user experience is:

1. **Double-click** any `.pdf` file on the desktop, in File Explorer, or from email attachments
2. The **default browser opens** to the Stirling-PDF server
3. The **file path is copied to clipboard** automatically
4. User clicks **Browse** in Stirling-PDF and picks the PDF (or pastes the path)
5. User **edits, annotates, or signs** the PDF in the browser
6. User clicks **Download** to save the final PDF

No local PDF editor is installed or required.

---

## Uninstall

1. Right-click `Unregister-PDFHandler.ps1` → **Run with PowerShell** (as Admin)
2. Confirm removal of install directory when prompted

This restores the previous PDF handler (Adobe, Edge, etc.).

---

## GPO / SCCM / Intune Deployment

For domain-joined machines, use the silent deployment script instead of `Register-PDFHandler.ps1`.

### Setup

1. Place the entire `client/` folder on a network share:
   ```
   \\fileserver\deploy\pdf-editor-suite\
   ├── config.ps1                  ← Edit this first
   ├── open-pdf.bat
   ├── Open-PDFInBrowser.ps1
   └── Deploy-PDFEditorSuite.ps1
   ```

2. Edit `config.ps1` on the share — set your server URL

### GPO Configuration

1. Open **Group Policy Management Console**
2. Create or edit a GPO linked to the target OU
3. Navigate to:
   - `Computer Configuration → Policies → Windows Settings → Scripts (Startup/Shutdown)`
4. Click **Startup → Show Files**, then **Add**
5. Script: `\\fileserver\deploy\pdf-editor-suite\Deploy-PDFEditorSuite.ps1`
6. Parameters (optional): `-ServerURL "https://pdf.yourdomain.com"`

### Per-OU URL Override

If different branches use different servers, use the `-ServerURL` parameter:

```
# Branch A GPO
Deploy-PDFEditorSuite.ps1 -ServerURL "https://pdf.branch-a.com"

# Branch B GPO
Deploy-PDFEditorSuite.ps1 -ServerURL "https://pdf.branch-b.com"
```

### GPO Uninstall

```
Deploy-PDFEditorSuite.ps1 -Uninstall
```

### Default App Association (GPO)

Windows 10/11 requires a DefaultAssociations XML to force the default app.
The deployment script auto-generates this at:

```
C:\Program Files\PDFEditorSuite\DefaultAssociations.xml
```

To apply it via GPO:

1. Navigate to:
   - `Computer Configuration → Admin Templates → Windows Components → File Explorer`
2. Enable **Set a default associations configuration file**
3. Set path to: `C:\Program Files\PDFEditorSuite\DefaultAssociations.xml`

### Logging

The deployment script logs to Windows Event Log:
- **Log**: Application
- **Source**: PDFEditorSuite

View logs:
```powershell
Get-EventLog -LogName Application -Source PDFEditorSuite | Format-Table -AutoSize
```

---

## Validation

Run `Validate-Client.ps1` on any machine to check the installation:

```powershell
.\Validate-Client.ps1
```

This tests:
- Installation files exist in the correct location
- `config.ps1` has a real server URL (not the default)
- Registry ProgId and `.pdf` association are set
- Server is reachable over HTTPS
- SSL certificate is valid and not expiring
- PowerShell execution policy allows scripts
- Handler and config scripts parse without errors

No admin required for read-only checks. Sample output:

```
  [PASS] Install directory exists: C:\Program Files\PDFEditorSuite
  [PASS] config.ps1 present
  [PASS] Open-PDFInBrowser.ps1 present
  [PASS] open-pdf.bat present
  [PASS] Server URL configured: https://pdf.example.com
  [PASS] ProgId registered: PDFEditorSuite.PDF
  [PASS] .pdf association set to PDFEditorSuite.PDF
  [PASS] Server reachable: https://pdf.example.com (HTTP 200)
  [PASS] SSL certificate valid (87 days remaining)
  [PASS] Execution policy: RemoteSigned
  [PASS] PowerShell version: 5.1.22621.4391

  11 passed  0 failed  0 warnings  0 skipped  (11 total)
  All tests passed!
```

---

## Troubleshooting

### "This app can't run on your PC"
The batch wrapper requires PowerShell, which is built into all supported
Windows versions. If you see this error, ensure `.bat` files are not
blocked by your security policy.

### Browser opens but server unreachable
- Verify the URL in `config.ps1` is correct
- Check that the SSL certificate is valid (no browser warnings)
- Ensure the client machine can reach the server (firewall, VPN, etc.)

### PDF still opens in Adobe/Edge
Windows 10/11 may override registry-based associations. Follow the
"Set Default App" step above to confirm the association manually.

### Script execution is blocked
If PowerShell blocks the script, run this once in an admin PowerShell:

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope LocalMachine
```

Or unblock the downloaded files:

```powershell
Get-ChildItem -Path .\client\ -Recurse | Unblock-File
```
