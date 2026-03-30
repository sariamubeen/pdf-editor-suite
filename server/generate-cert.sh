#!/usr/bin/env bash
# =============================================================================
# PDF Editor Suite — Generate X.509 Signing Certificate
# =============================================================================
# Creates a PKCS#12 (.p12) certificate for digitally signing PDFs.
# The signed PDFs will show this certificate's org name in PDF readers.
#
# Usage:  chmod +x generate-cert.sh && ./generate-cert.sh
# Output: data/certs/signing.p12
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
CERT_DIR="$SCRIPT_DIR/data/certs"

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║   PDF Signing Certificate Generator                  ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# ── Check openssl ────────────────────────────────────────────────────────────

if ! command -v openssl &>/dev/null; then
    err "OpenSSL is not installed."
    err "  Ubuntu/Debian: sudo apt install openssl"
    err "  Rocky/RHEL:    sudo dnf install openssl"
    exit 1
fi

# ── Gather info ──────────────────────────────────────────────────────────────

echo "Enter certificate details (press Enter for defaults):"
echo ""

read -rp "Organization Name [My Organization]: " ORG_NAME
ORG_NAME="${ORG_NAME:-My Organization}"

read -rp "Common Name [Document Signing]: " COMMON_NAME
COMMON_NAME="${COMMON_NAME:-Document Signing}"

read -rp "Country Code (2 letters) [US]: " COUNTRY
COUNTRY="${COUNTRY:-US}"

read -rp "City / Locality []: " CITY
CITY="${CITY:-}"

read -rp "Validity in days [730]: " VALIDITY
VALIDITY="${VALIDITY:-730}"

read -rsp "PKCS#12 Export Password: " P12_PASSWORD
echo ""
if [ -z "$P12_PASSWORD" ]; then
    err "Password cannot be empty."
    exit 1
fi

# ── Build subject ────────────────────────────────────────────────────────────

SUBJECT="/O=$ORG_NAME/CN=$COMMON_NAME/C=$COUNTRY"
if [ -n "$CITY" ]; then
    SUBJECT="$SUBJECT/L=$CITY"
fi

# ── Generate ─────────────────────────────────────────────────────────────────

mkdir -p "$CERT_DIR"

TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

KEY_FILE="$TEMP_DIR/key.pem"
CERT_FILE="$TEMP_DIR/cert.pem"
P12_FILE="$CERT_DIR/signing.p12"

log "Generating 4096-bit RSA key pair..."
openssl req -x509 -newkey rsa:4096 \
    -keyout "$KEY_FILE" \
    -out "$CERT_FILE" \
    -days "$VALIDITY" \
    -nodes \
    -subj "$SUBJECT" \
    2>/dev/null

log "Packaging as PKCS#12..."
openssl pkcs12 -export \
    -out "$P12_FILE" \
    -inkey "$KEY_FILE" \
    -in "$CERT_FILE" \
    -name "$ORG_NAME Document Signing" \
    -passout "pass:$P12_PASSWORD" \
    2>/dev/null

# ── Verify ───────────────────────────────────────────────────────────────────

log "Verifying certificate..."
openssl pkcs12 -in "$P12_FILE" -passin "pass:$P12_PASSWORD" -nokeys 2>/dev/null | \
    openssl x509 -noout -subject -dates 2>/dev/null

# ── Set permissions ──────────────────────────────────────────────────────────

chmod 600 "$P12_FILE"
log "Certificate saved to: $P12_FILE"

# ── Done ─────────────────────────────────────────────────────────────────────

echo ""
echo -e "${CYAN}╔══════════════════════════════════════════════════════╗${NC}"
echo -e "${CYAN}║  Certificate Ready                                   ║${NC}"
echo -e "${CYAN}╠══════════════════════════════════════════════════════╣${NC}"
echo -e "${CYAN}║${NC}  File     : data/certs/signing.p12                   ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  Org      : $ORG_NAME"
echo -e "${CYAN}║${NC}  Validity : $VALIDITY days"
echo -e "${CYAN}║${NC}                                                     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  ${YELLOW}Usage in Stirling-PDF:${NC}                              ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  1. Go to Security → Certificate Signing            ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  2. Upload your PDF                                 ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  3. Select 'Custom certificate'                     ${CYAN}║${NC}"
echo -e "${CYAN}║${NC}  4. Upload signing.p12 with your password            ${CYAN}║${NC}"
echo -e "${CYAN}╚══════════════════════════════════════════════════════╝${NC}"
echo ""
warn "Keep the PKCS#12 password safe — you'll need it when signing PDFs."
warn "Store it in your password manager."
