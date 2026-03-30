#!/usr/bin/env bash
# =============================================================================
# PDF Editor Suite — Server Setup
# =============================================================================
# Usage:  chmod +x setup.sh && ./setup.sh
# Tested: Ubuntu 22.04/24.04, Rocky Linux 8/9, Debian 12
# =============================================================================

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log()  { echo -e "${GREEN}[✓]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✗]${NC} $*" >&2; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║       PDF Editor Suite — Server Setup                ║"
echo "║                                      by sariamubeen ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Pre-flight checks ───────────────────────────────────────────────────────

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

# ── Create data directories ─────────────────────────────────────────────────

log "Creating data directories..."
mkdir -p data/{configs,logs,custom-files,pipeline,certs}

# ── Environment file ────────────────────────────────────────────────────────

if [ ! -f .env ]; then
    cp .env.example .env
    warn "Created .env from template — edit it before proceeding!"
    warn "  nano $SCRIPT_DIR/.env"
    echo ""
    read -rp "Press Enter after editing .env (or Ctrl+C to abort)..."
fi

log "Environment file ready"

# ── Read port from .env ─────────────────────────────────────────────────────

STIRLING_PORT=$(grep -E '^STIRLING_PORT=' .env 2>/dev/null | cut -d= -f2)
STIRLING_PORT="${STIRLING_PORT:-8080}"

log "Using port: $STIRLING_PORT"

# ── Pull and start ──────────────────────────────────────────────────────────

log "Pulling Stirling-PDF image..."
$COMPOSE_CMD pull

log "Starting Stirling-PDF..."
$COMPOSE_CMD up -d

# ── Wait for healthy ────────────────────────────────────────────────────────

log "Waiting for Stirling-PDF to become healthy..."
ATTEMPTS=0
MAX_ATTEMPTS=30
until [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; do
    if curl -sf http://127.0.0.1:${STIRLING_PORT}/api/v1/info/status &>/dev/null; then
        break
    fi
    ATTEMPTS=$((ATTEMPTS + 1))
    sleep 2
done

if [ "$ATTEMPTS" -ge "$MAX_ATTEMPTS" ]; then
    warn "Stirling-PDF did not respond within 60 seconds."
    warn "Check logs: $COMPOSE_CMD logs -f stirling-pdf"
else
    log "Stirling-PDF is running on http://127.0.0.1:${STIRLING_PORT}"
fi

# ── Summary ─────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Setup Complete                      by sariamubeen ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  Internal URL : http://127.0.0.1:${STIRLING_PORT}               ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  Container    : stirling-pdf                        ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}                                                     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}Next steps:${NC}                                       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  1. Access directly via http://SERVER_IP:${STIRLING_PORT}       ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     OR add proxy host in Nginx Proxy Manager        ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     → Forward pdf.yourdomain.com → 127.0.0.1:${STIRLING_PORT}  ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}     → Enable SSL (Let's Encrypt)                    ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  2. Login and change admin password                 ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  3. (Optional) Run generate-cert.sh for custom cert ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  4. Deploy client/ folder to Windows machines       ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Useful commands:"
echo "  $COMPOSE_CMD logs -f stirling-pdf   # View logs"
echo "  $COMPOSE_CMD restart stirling-pdf   # Restart service"
echo "  $COMPOSE_CMD down                   # Stop service"
echo "  $COMPOSE_CMD pull && $COMPOSE_CMD up -d  # Update image"
