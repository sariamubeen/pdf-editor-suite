# PDF Editor Suite
**by sariamubeen**

**Self-hosted PDF editing, annotation, and digital signing — launched directly from a Windows desktop.**

Double-click any PDF → browser opens → edit, annotate, sign → download the final PDF. No local PDF editor needed.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│  WINDOWS CLIENT                                         │
│                                                         │
│  User double-clicks .pdf                                │
│       │                                                 │
│       ▼                                                 │
│  open-pdf.bat  ─►  Open-PDFInBrowser.ps1                │
│       │                                                 │
│       ▼                                                 │
│  Default browser opens https://pdf.example.com          │
│  PDF file path copied to clipboard                      │
└────────────────────────┬────────────────────────────────┘
                         │ HTTPS
                         ▼
┌─────────────────────────────────────────────────────────┐
│  LINUX SERVER                                           │
│                                                         │
│  Nginx Proxy Manager (HTTPS termination)                │
│       │                                                 │
│       ▼                                                 │
│  Stirling-PDF (Docker)                                  │
│    ├── Edit PDF (text, images, pages)                   │
│    ├── Annotate (highlights, drawings, notes)           │
│    ├── Form filling                                     │
│    ├── Digital signature (X.509 certificate)            │
│    ├── Handwritten signature                            │
│    ├── Merge / split / compress / OCR                   │
│    └── Download final PDF                               │
└─────────────────────────────────────────────────────────┘
```

---

## Quick Start

### Server (5 minutes)

```bash
git clone https://github.com/sariamubeen/pdf-editor-suite.git
cd pdf-editor-suite/server
chmod +x setup.sh generate-cert.sh
./setup.sh
```

Then add a proxy host in Nginx Proxy Manager. See [Server Setup Guide](docs/SERVER-SETUP.md).

### Windows Client (2 minutes)

1. Copy the `client/` folder to each Windows machine
2. Edit `client/config.ps1` — set your server URL
3. Right-click `Register-PDFHandler.ps1` → **Run with PowerShell as Administrator**

See [Client Setup Guide](docs/CLIENT-SETUP.md).

### Validate Everything

```bash
# Server validation
cd pdf-editor-suite/server
./validate.sh --url https://pdf.yourdomain.com --pass YOUR_ADMIN_PASS --full
```

```powershell
# Client validation (on Windows)
.\Validate-Client.ps1
```

---

## Deployment Modes

| Mode | Script | Use Case |
|------|--------|----------|
| **Manual** | `Register-PDFHandler.ps1` | Single machine, run interactively as Admin |
| **GPO / SCCM / Intune** | `Deploy-PDFEditorSuite.ps1` | Domain-joined machines, silent deployment |
| **Uninstall** | `Unregister-PDFHandler.ps1` | Interactive revert on one machine |
| **GPO Uninstall** | `Deploy-PDFEditorSuite.ps1 -Uninstall` | Silent removal across domain |

### GPO Deployment

1. Place the `client/` folder on a network share (e.g., `\\fileserver\deploy\pdf-editor-suite\`)
2. Edit `config.ps1` on the share — set `$PDFEditorURL`
3. Create a GPO → **Computer Configuration → Policies → Windows Settings → Scripts → Startup**
4. Add script: `\\fileserver\deploy\pdf-editor-suite\Deploy-PDFEditorSuite.ps1`
5. Optional parameter: `-ServerURL "https://pdf.yourdomain.com"` (overrides config.ps1)

The script is idempotent, logs to Windows Event Log (`Application → PDFEditorSuite`), and skips machines where it's already installed.

---

## Requirements

| Component | Minimum |
|-----------|---------|
| Server OS | Any Linux with Docker + Docker Compose |
| Reverse Proxy | Nginx Proxy Manager (existing) |
| Client OS | Windows 10 / 11 / Server 2019+ |
| Browser | Any modern browser (Chrome, Edge, Firefox) |
| Network | Client must reach server over HTTPS |

---

## What's Included

```
pdf-editor-suite/
├── README.md                         # This file
├── LICENSE
├── .gitignore
├── server/
│   ├── docker-compose.yml            # Stirling-PDF container
│   ├── .env.example                  # Environment template
│   ├── setup.sh                      # Automated server setup
│   ├── generate-cert.sh              # X.509 signing certificate generator
│   └── validate.sh                   # Server health & end-to-end test
├── client/
│   ├── config.ps1                    # ⚙ Single config file (edit this)
│   ├── open-pdf.bat                  # Batch wrapper (file association target)
│   ├── Open-PDFInBrowser.ps1         # Main handler script
│   ├── Register-PDFHandler.ps1       # Install file association (run once)
│   ├── Unregister-PDFHandler.ps1     # Revert file association
│   ├── Deploy-PDFEditorSuite.ps1     # GPO / SCCM / Intune deployment
│   └── Validate-Client.ps1           # Client installation validator
└── docs/
    ├── SERVER-SETUP.md               # Full server deployment guide
    ├── CLIENT-SETUP.md               # Windows client install guide
    └── CERTIFICATE-GUIDE.md          # Digital signature certificate setup
```

---

## Success Criteria

| Criterion | Status |
|-----------|--------|
| PDF opened from Windows desktop into browser | ✅ |
| PDF can be edited (text, annotations, fields) | ✅ |
| Digital signature can be applied | ✅ |
| Resulting PDF is valid and tamper-evident | ✅ |
| No local PDF editor required on client | ✅ |
| Reverse proxy + HTTPS | ✅ |
| Fully open-source and self-hosted | ✅ |

---

## Tech Stack

- **[Stirling-PDF](https://github.com/Stirling-Tools/Stirling-PDF)** — Open-source PDF toolkit (AGPL-3.0), 50+ tools, REST API, multi-user auth
- **Nginx Proxy Manager** — HTTPS termination with Let's Encrypt
- **PowerShell / Batch** — Windows desktop integration
- **Docker Compose** — Server deployment

---

## License

MIT — see [LICENSE](LICENSE).

Stirling-PDF is licensed under AGPL-3.0 by its authors.
