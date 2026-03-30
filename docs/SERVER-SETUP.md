# Server Setup Guide

## Prerequisites

- Linux server (Ubuntu, Debian, Rocky, RHEL, or similar)
- Docker and Docker Compose installed
- Nginx Proxy Manager running and accessible
- A domain or subdomain (e.g., `pdf.yourdomain.com`)

---

## Step 1: Deploy Stirling-PDF

```bash
# Clone the repo
git clone https://github.com/YOUR_ORG/pdf-editor-suite.git
cd pdf-editor-suite/server

# Create .env from template
cp .env.example .env

# Edit configuration
nano .env
```

Set these values in `.env`:

| Variable | Example | Description |
|----------|---------|-------------|
| `STIRLING_ADMIN_PASSWORD` | `MyStr0ngP@ss!` | Initial admin password |
| `CERT_ORG_NAME` | `Acme Corp` | Name shown on signed PDFs |
| `STIRLING_PORT` | `8080` | Port to listen on (change if 8080 is taken) |

Then run setup:

```bash
chmod +x setup.sh
./setup.sh
```

Stirling-PDF will be running on `http://127.0.0.1:<YOUR_PORT>`.

---

## Step 2: Access — Pick One

### Option A: Direct LAN access (no domain, no NPM)

Just open `http://SERVER_IP:PORT` from any machine on the same network. Done.

Set the same address in the Windows client `config.ps1`:
```powershell
$PDFEditorURL = "http://192.168.1.50:8080"
```

### Option B: Nginx Proxy Manager (domain + HTTPS)

1. Open your Nginx Proxy Manager admin panel
2. Go to **Proxy Hosts → Add Proxy Host**
3. Fill in:

| Field | Value |
|-------|-------|
| Domain Names | `pdf.yourdomain.com` |
| Scheme | `http` |
| Forward Hostname / IP | `127.0.0.1` (or server LAN IP if NPM is on a different host) |
| Forward Port | Value from `STIRLING_PORT` in `.env` (default: `8080`) |
| Block Common Exploits | ✅ |
| Websockets Support | ✅ |

4. Go to the **SSL** tab:

| Field | Value |
|-------|-------|
| SSL Certificate | Request a new SSL Certificate |
| Force SSL | ✅ |
| HTTP/2 Support | ✅ |

5. Click **Save**

> **If NPM is on a different server** (e.g., a separate VPS), use the
> Stirling-PDF server's LAN IP or Tailscale IP as the forward hostname
> instead of `127.0.0.1`. Ensure the port is reachable between servers.

### Custom Nginx Configuration (Optional)

If your PDFs are large, add this in NPM's **Advanced** tab:

```nginx
client_max_body_size 100m;
proxy_read_timeout 300s;
proxy_send_timeout 300s;
```

---

## Step 3: First Login

1. Browse to `https://pdf.yourdomain.com`
2. Log in with:
   - Username: `admin`
   - Password: whatever you set in `.env`
3. **Change the admin password immediately** via Account Settings
4. Create user accounts for your team

---

## Step 4: Generate a Signing Certificate (Optional)

The auto-generated server certificate works out of the box for basic signing.
For a certificate with your organization's name:

```bash
cd pdf-editor-suite/server
chmod +x generate-cert.sh
./generate-cert.sh
```

Follow the prompts. The certificate is saved to `data/certs/signing.p12`.

When signing PDFs in Stirling-PDF, select **Custom certificate** and upload
the `.p12` file with the password you set.

See [Certificate Guide](CERTIFICATE-GUIDE.md) for advanced options.

---

## Managing the Service

### Validate deployment
```bash
# Quick check (container + API + port binding)
./validate.sh

# Full check including public URL and SSL
./validate.sh --url https://pdf.yourdomain.com

# End-to-end: upload → sign → download
./validate.sh --url https://pdf.yourdomain.com --pass YOUR_ADMIN_PASS --full

# CI/quiet mode (only show failures)
./validate.sh --quiet
```

The validation script tests:
- Docker container status and health
- Local API responsiveness
- Public URL reachability and SSL certificate validity
- Signing certificate configuration
- Port binding security (localhost-only)
- End-to-end PDF signing via API (with `--full`)

### View logs
```bash
cd pdf-editor-suite/server
docker compose logs -f stirling-pdf
```

### Restart
```bash
docker compose restart stirling-pdf
```

### Stop
```bash
docker compose down
```

### Update to latest version
```bash
docker compose pull
docker compose up -d
```

### Check health
```bash
curl -s http://127.0.0.1:8080/api/v1/info/status | jq .
```

---

## Data & Backups

All persistent data is in `server/data/`:

| Directory | Contents |
|-----------|----------|
| `data/configs/` | Application settings |
| `data/certs/` | Signing certificates |
| `data/logs/` | Log files |
| `data/custom-files/` | Branding / custom assets |
| `data/pipeline/` | Automation pipeline configs |

Back up the entire `data/` directory to preserve configuration.
