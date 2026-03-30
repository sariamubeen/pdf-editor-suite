#!/usr/bin/env bash
# =============================================================================
# PDF Editor Suite - Server Setup
# by sariamubeen
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[!!]${NC} $*"; }
err()  { echo -e "${RED}[ERR]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}"
echo "+==========================================================+"
echo "|  PDF Editor Suite - Server Setup                          |"
echo "|                                          by sariamubeen  |"
echo "+==========================================================+"
echo -e "${NC}"

# -- Pre-flight checks -------------------------------------------------------

if ! command -v docker &>/dev/null; then
    err "Docker is not installed. Install it first:"
    err "  https://docs.docker.com/engine/install/"
    exit 1
fi

if ! docker compose version &>/dev/null 2>&1; then
    if ! docker-compose version &>/dev/null 2>&1; then
        err "Docker Compose is not installed."
        exit 1
    fi
    COMPOSE_CMD="docker-compose"
else
    COMPOSE_CMD="docker compose"
fi

log "Docker and Docker Compose detected"

# -- Detect server IP ---------------------------------------------------------

SERVER_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
if [ -z "$SERVER_IP" ]; then
    SERVER_IP=$(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}')
fi
SERVER_IP="${SERVER_IP:-YOUR_SERVER_IP}"

log "Detected server IP: $SERVER_IP"

# -- Environment file ---------------------------------------------------------

if [ ! -f .env ]; then
    cp .env.example .env
    sed -i "s/SERVER_IP=.*/SERVER_IP=$SERVER_IP/" .env
    log "Created .env with detected IP: $SERVER_IP"
else
    log "Using existing .env file"
fi

source .env

APP_PORT="${APP_PORT:-8080}"
ONLYOFFICE_PORT="${ONLYOFFICE_PORT:-8443}"

# -- Build and start ----------------------------------------------------------

log "Building web app..."
$COMPOSE_CMD build app

log "Pulling ONLYOFFICE Document Server..."
$COMPOSE_CMD pull onlyoffice

log "Starting services..."
$COMPOSE_CMD up -d

# -- Wait for ONLYOFFICE (takes a while on first boot) -----------------------

log "Waiting for ONLYOFFICE Document Server to start (this may take 1-2 minutes)..."
ATTEMPTS=0
MAX_ATTEMPTS=60
until [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; do
    if curl -sf http://127.0.0.1:${ONLYOFFICE_PORT}/healthcheck &>/dev/null; then
        break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep 3
done

if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    warn "ONLYOFFICE did not respond within 3 minutes."
    warn "Check logs: $COMPOSE_CMD logs -f onlyoffice"
else
    log "ONLYOFFICE Document Server is running"
fi

# -- Wait for web app ---------------------------------------------------------

log "Waiting for web app..."
ATTEMPTS=0
MAX_ATTEMPTS=15
until [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; do
    if curl -sf http://127.0.0.1:${APP_PORT}/health &>/dev/null; then
        break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep 2
done

if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    warn "Web app did not respond."
    warn "Check logs: $COMPOSE_CMD logs -f pdf-editor-app"
else
    log "Web app is running"
fi

# -- Summary ------------------------------------------------------------------

echo ""
echo -e "${CYAN}+==========================================================+${NC}"
echo -e "${CYAN}|  Setup Complete                          by sariamubeen  |${NC}"
echo -e "${CYAN}+==========================================================+${NC}"
echo ""
echo -e "  PDF Editor:  ${GREEN}http://${SERVER_IP}:${APP_PORT}${NC}"
echo -e "  ONLYOFFICE:  http://${SERVER_IP}:${ONLYOFFICE_PORT}"
echo ""
echo -e "  ${YELLOW}Windows client:${NC}"
echo -e "  Run INSTALL.bat and enter: ${GREEN}http://${SERVER_IP}:${APP_PORT}${NC}"
echo ""
echo -e "  ${YELLOW}Open firewall ports:${NC}"
echo -e "  sudo ufw allow ${APP_PORT}/tcp"
echo -e "  sudo ufw allow ${ONLYOFFICE_PORT}/tcp"
echo ""
echo "Useful commands:"
echo "  $COMPOSE_CMD logs -f             # View all logs"
echo "  $COMPOSE_CMD restart             # Restart services"
echo "  $COMPOSE_CMD down                # Stop services"
echo "  $COMPOSE_CMD up -d --build       # Rebuild and restart"
