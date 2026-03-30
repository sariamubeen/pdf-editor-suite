# Server Setup Guide

## What You Need

- A Linux machine (Ubuntu, Debian, Rocky, etc.)
- Docker and Docker Compose installed
- At least 4 GB RAM
- Network access from Windows machines

---

## Step 1: Install Docker (if not already installed)

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
```

Log out and log back in, then verify:

```bash
docker --version
docker compose version
```

---

## Step 2: Get the code

```bash
git clone https://github.com/sariamubeen/pdf-editor-suite.git
cd pdf-editor-suite/server
```

---

## Step 3: Run setup

```bash
chmod +x setup.sh
./setup.sh
```

The script will:
- Detect your server's IP address
- Create the configuration file
- Build and start the containers
- Wait for everything to be ready

This takes 2-3 minutes on first run (ONLYOFFICE is a large image).

---

## Step 4: Verify

Open a browser and go to:

```
http://YOUR_SERVER_IP:8080
```

You should see the PDF Editor Suite upload page. Try uploading a PDF -- it should open in the ONLYOFFICE editor.

---

## Step 5: Open firewall ports

If your server has a firewall, open these two ports:

**Ubuntu/Debian:**
```bash
sudo ufw allow 8080/tcp
sudo ufw allow 8443/tcp
sudo ufw reload
```

**RHEL/Rocky/AlmaLinux:**
```bash
sudo firewall-cmd --add-port=8080/tcp --permanent
sudo firewall-cmd --add-port=8443/tcp --permanent
sudo firewall-cmd --reload
```

---

## Configuration

The configuration file is `server/.env`. Edit it if you need to change anything:

```bash
nano .env
```

| Setting | Default | Description |
|---------|---------|-------------|
| SERVER_IP | Auto-detected | Your server's private IP |
| APP_PORT | 8080 | Web app port (upload + editor) |
| ONLYOFFICE_PORT | 8443 | ONLYOFFICE Document Server port |
| JWT_SECRET | pdfeditorsuite | Security token (change in production) |

After changing `.env`, restart:

```bash
docker compose down
docker compose up -d
```

---

## Useful Commands

| Command | What it does |
|---------|-------------|
| `docker compose ps` | Show running containers |
| `docker compose logs -f` | View live logs |
| `docker compose restart` | Restart everything |
| `docker compose down` | Stop everything |
| `docker compose up -d --build` | Rebuild and restart |

---

## Troubleshooting

**"Connection refused" on port 8080**
- Check if containers are running: `docker compose ps`
- Check logs: `docker compose logs -f pdf-editor-app`
- Make sure firewall allows port 8080

**"Connection refused" on port 8443**
- ONLYOFFICE takes 1-2 minutes to start on first boot
- Check: `docker compose logs -f onlyoffice`
- Wait and try again

**Editor loads but PDF doesn't appear**
- ONLYOFFICE needs to reach the web app. Check that both containers are on the same Docker network: `docker network ls`
- Check ONLYOFFICE logs for errors: `docker compose logs onlyoffice | tail -50`

**Out of memory**
- ONLYOFFICE needs at least 2 GB RAM. Check: `free -h`
- If low on RAM, add swap: `sudo fallocate -l 4G /swapfile && sudo chmod 600 /swapfile && sudo mkswap /swapfile && sudo swapon /swapfile`
