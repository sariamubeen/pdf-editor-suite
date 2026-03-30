# PDF Editor Suite
**by sariamubeen**

**Double-click any PDF on Windows -- it opens in a full browser-based editor. Edit, annotate, sign, download.**

No local PDF software needed. Self-hosted on your private network.

---

## How It Works

```
Windows Client                          Linux Server (Docker)
+----------------+                    +---------------------------+
| Double-click   |  Upload PDF via    |  Web App (:8080)          |
| any .pdf file  |---- HTTP POST ---->|  Accepts upload           |
|                |                    |  Serves editor page       |
| Browser opens  |<--- edit URL ------|  Serves PDF files         |
| ONLYOFFICE     |                    +-------------+-------------+
| editor         |                                  |
+----------------+                    +-------------v-------------+
                                      | ONLYOFFICE Document       |
                                      | Server (:8443)            |
                                      | Full PDF editor in browser|
                                      +---------------------------+
```

---

## Quick Start

### Server (Linux - 5 minutes)

```bash
git clone https://github.com/sariamubeen/pdf-editor-suite.git
cd pdf-editor-suite/server
chmod +x setup.sh
./setup.sh
```

The setup script will:
- Detect your server IP
- Build the web app container
- Pull ONLYOFFICE Document Server
- Start everything
- Show you the URL to use

### Windows Client (30 seconds)

1. Copy `INSTALL.bat` to the Windows machine
2. Double-click `INSTALL.bat`
3. Press Enter to accept default server URL (or type your own)
4. Done -- double-click any PDF to edit it

To uninstall: double-click `UNINSTALL.bat`

---

## What You Get

- **Full PDF editing** in the browser (ONLYOFFICE)
- **Annotations**: highlights, comments, drawings
- **Digital signatures**
- **Form filling**
- **No manual upload**: double-click PDF, it auto-uploads and opens in editor
- **No login required** on private networks
- **Debug logging**: check `%TEMP%\PDFEditorSuite-debug.log` if something goes wrong

---

## Requirements

| Component | Minimum |
|-----------|---------|
| Server OS | Any Linux with Docker + Docker Compose |
| Server RAM | 4 GB minimum (ONLYOFFICE needs ~2 GB) |
| Client OS | Windows 10 / 11 / Server 2019+ |
| Browser | Edge or Chrome |
| Network | Client must reach server on ports 8080 + 8443 |

---

## Files

```
pdf-editor-suite/
+-- README.md
+-- LICENSE
+-- INSTALL.bat              # Windows one-click installer
+-- UNINSTALL.bat            # Windows uninstaller
+-- server/
    +-- docker-compose.yml   # ONLYOFFICE + Web App
    +-- .env.example         # Server configuration
    +-- setup.sh             # Automated server setup
    +-- app/
        +-- app.py           # Flask web app (upload, serve, editor)
        +-- Dockerfile
        +-- requirements.txt
```

---

## Configuration

Edit `server/.env`:

```
SERVER_IP=172.20.4.58        # Your server's private IP
APP_PORT=8080                # Web app port
ONLYOFFICE_PORT=8443         # ONLYOFFICE port
JWT_SECRET=pdfeditorsuite    # Change to something random
```

---

## Useful Commands

```bash
cd pdf-editor-suite/server

docker compose logs -f              # View all logs
docker compose logs -f onlyoffice   # ONLYOFFICE logs only
docker compose logs -f pdf-editor-app  # Web app logs only
docker compose restart              # Restart everything
docker compose down                 # Stop everything
docker compose up -d --build        # Rebuild and restart
```

---

## Tech Stack

- **[ONLYOFFICE Document Server](https://github.com/ONLYOFFICE/Docker-DocumentServer)** - PDF editor engine (AGPL-3.0)
- **Flask** - Python web app for file management
- **Docker Compose** - Server deployment
- **Batch / PowerShell** - Windows client integration

---

## License

MIT

ONLYOFFICE Document Server is licensed under AGPL-3.0 by its authors.
