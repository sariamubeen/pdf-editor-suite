#!/usr/bin/env bash
# =============================================================================
# PDF Editor Suite — Server Validation Script
# =============================================================================
# Tests all critical components of the server deployment:
#   1. Docker container is running and healthy
#   2. Stirling-PDF API responds
#   3. Authentication works
#   4. PDF upload + sign + download works end-to-end
#   5. Reverse proxy (NPM) is routing correctly
#   6. Signing certificate is configured
#
# Usage:  chmod +x validate.sh && ./validate.sh [OPTIONS]
#
# Options:
#   --url URL     Public URL to test (e.g., https://pdf.example.com)
#   --user USER   Admin username (default: admin)
#   --pass PASS   Admin password
#   --full        Run full end-to-end test (upload → sign → download)
#   --quiet       Only show failures
# =============================================================================

set -euo pipefail

# ── Defaults ─────────────────────────────────────────────────────────────────

LOCAL_URL="http://127.0.0.1:8080"
PUBLIC_URL=""
ADMIN_USER="admin"
ADMIN_PASS=""
FULL_TEST=false
QUIET=false
CONTAINER_NAME="stirling-pdf"

# ── Colors ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0

pass() { PASS_COUNT=$((PASS_COUNT + 1)); echo -e "  ${GREEN}✓ PASS${NC}  $1"; }
fail() { FAIL_COUNT=$((FAIL_COUNT + 1)); echo -e "  ${RED}✗ FAIL${NC}  $1"; }
warn() { WARN_COUNT=$((WARN_COUNT + 1)); echo -e "  ${YELLOW}! WARN${NC}  $1"; }
skip() { SKIP_COUNT=$((SKIP_COUNT + 1)); if [ "$QUIET" = false ]; then echo -e "  ${DIM}– SKIP${NC}  $1"; fi; }
info() { if [ "$QUIET" = false ]; then echo -e "  ${DIM}  INFO${NC}  $1"; fi; }

# ── Parse arguments ──────────────────────────────────────────────────────────

while [[ $# -gt 0 ]]; do
    case "$1" in
        --url)    PUBLIC_URL="$2"; shift 2 ;;
        --user)   ADMIN_USER="$2"; shift 2 ;;
        --pass)   ADMIN_PASS="$2"; shift 2 ;;
        --full)   FULL_TEST=true; shift ;;
        --quiet)  QUIET=true; shift ;;
        -h|--help)
            echo "Usage: $0 [--url URL] [--user USER] [--pass PASS] [--full] [--quiet]"
            exit 0
            ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

# ── Banner ───────────────────────────────────────────────────────────────────

echo -e "${CYAN}"
echo "╔══════════════════════════════════════════════════════╗"
echo "║  PDF Editor Suite — Validation                       ║"
echo "╚══════════════════════════════════════════════════════╝"
echo -e "${NC}"

# =============================================================================
# TEST GROUP 1: Docker Container
# =============================================================================

echo -e "${CYAN}── Docker Container ────────────────────────────────────${NC}"

# 1.1 Container exists
if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
    pass "Container '$CONTAINER_NAME' exists"
else
    fail "Container '$CONTAINER_NAME' not found"
    echo -e "${RED}  Run: docker compose up -d${NC}"
    exit 1
fi

# 1.2 Container is running
CONTAINER_STATUS=$(docker inspect -f '{{.State.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "unknown")
if [ "$CONTAINER_STATUS" = "running" ]; then
    pass "Container is running"
else
    fail "Container status: $CONTAINER_STATUS (expected: running)"
fi

# 1.3 Health check
HEALTH=$(docker inspect -f '{{.State.Health.Status}}' "$CONTAINER_NAME" 2>/dev/null || echo "none")
case "$HEALTH" in
    healthy)   pass "Container health: healthy" ;;
    starting)  warn "Container health: starting (still booting)" ;;
    unhealthy) fail "Container health: unhealthy" ;;
    none)      warn "No health check configured" ;;
    *)         warn "Container health: $HEALTH" ;;
esac

# 1.4 Uptime
STARTED=$(docker inspect -f '{{.State.StartedAt}}' "$CONTAINER_NAME" 2>/dev/null || echo "")
if [ -n "$STARTED" ]; then
    info "Started at: $STARTED"
fi

echo ""

# =============================================================================
# TEST GROUP 2: Local API
# =============================================================================

echo -e "${CYAN}── Local API ($LOCAL_URL) ───────────────────────────────${NC}"

# 2.1 Status endpoint
HTTP_CODE=$(curl -so /dev/null -w '%{http_code}' --max-time 10 "$LOCAL_URL/api/v1/info/status" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    pass "Status endpoint responds (HTTP $HTTP_CODE)"
elif [ "$HTTP_CODE" = "000" ]; then
    fail "Cannot reach $LOCAL_URL (connection refused or timeout)"
else
    warn "Status endpoint returned HTTP $HTTP_CODE"
fi

# 2.2 Login page loads
HTTP_CODE=$(curl -so /dev/null -w '%{http_code}' --max-time 10 "$LOCAL_URL/login" 2>/dev/null || echo "000")
if [ "$HTTP_CODE" = "200" ]; then
    pass "Login page loads (HTTP $HTTP_CODE)"
else
    warn "Login page returned HTTP $HTTP_CODE"
fi

# 2.3 Authentication (if credentials provided)
if [ -n "$ADMIN_PASS" ]; then
    AUTH_RESPONSE=$(curl -s --max-time 10 -o /dev/null -w '%{http_code}' \
        -X POST "$LOCAL_URL/login" \
        -d "username=$ADMIN_USER&password=$ADMIN_PASS" \
        -c /tmp/pdf-suite-cookies.txt \
        -L 2>/dev/null || echo "000")

    if [ "$AUTH_RESPONSE" = "200" ]; then
        pass "Authentication successful (user: $ADMIN_USER)"
    else
        fail "Authentication failed (HTTP $AUTH_RESPONSE)"
    fi
else
    skip "Authentication test (no --pass provided)"
fi

echo ""

# =============================================================================
# TEST GROUP 3: Reverse Proxy (Public URL)
# =============================================================================

echo -e "${CYAN}── Reverse Proxy ───────────────────────────────────────${NC}"

if [ -n "$PUBLIC_URL" ]; then
    # 3.1 HTTPS reachable
    HTTP_CODE=$(curl -so /dev/null -w '%{http_code}' --max-time 15 "$PUBLIC_URL" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        pass "Public URL reachable: $PUBLIC_URL (HTTP $HTTP_CODE)"
    elif [ "$HTTP_CODE" = "000" ]; then
        fail "Cannot reach $PUBLIC_URL"
    else
        warn "Public URL returned HTTP $HTTP_CODE"
    fi

    # 3.2 SSL certificate valid
    if echo "$PUBLIC_URL" | grep -q "https://"; then
        DOMAIN=$(echo "$PUBLIC_URL" | sed 's|https://||' | sed 's|/.*||')
        SSL_EXPIRY=$(echo | openssl s_client -servername "$DOMAIN" -connect "$DOMAIN:443" 2>/dev/null | \
            openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
        if [ -n "$SSL_EXPIRY" ]; then
            EXPIRY_EPOCH=$(date -d "$SSL_EXPIRY" +%s 2>/dev/null || date -jf "%b %d %T %Y %Z" "$SSL_EXPIRY" +%s 2>/dev/null || echo "0")
            NOW_EPOCH=$(date +%s)
            DAYS_LEFT=$(( (EXPIRY_EPOCH - NOW_EPOCH) / 86400 ))

            if [ "$DAYS_LEFT" -gt 30 ]; then
                pass "SSL certificate valid ($DAYS_LEFT days remaining)"
            elif [ "$DAYS_LEFT" -gt 0 ]; then
                warn "SSL certificate expiring soon ($DAYS_LEFT days remaining)"
            else
                fail "SSL certificate expired!"
            fi
            info "Expires: $SSL_EXPIRY"
        else
            warn "Could not check SSL certificate"
        fi
    fi

    # 3.3 Public status endpoint
    HTTP_CODE=$(curl -so /dev/null -w '%{http_code}' --max-time 15 "$PUBLIC_URL/api/v1/info/status" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ]; then
        pass "Public API status endpoint responds"
    else
        warn "Public API status returned HTTP $HTTP_CODE"
    fi
else
    skip "Reverse proxy tests (no --url provided)"
fi

echo ""

# =============================================================================
# TEST GROUP 4: Signing Certificate
# =============================================================================

echo -e "${CYAN}── Signing Certificate ─────────────────────────────────${NC}"

CERT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/data/certs"

# 4.1 Auto-generated cert (check docker env)
AUTO_CERT=$(docker inspect "$CONTAINER_NAME" 2>/dev/null | grep -c "SERVERCERTIFICATE_ENABLED=true" || echo "0")
if [ "$AUTO_CERT" -gt 0 ]; then
    pass "Auto-generated server certificate enabled"
else
    warn "Auto-generated server certificate not enabled"
fi

# 4.2 Custom certificate
if [ -d "$CERT_DIR" ]; then
    P12_FILES=$(find "$CERT_DIR" -name "*.p12" -o -name "*.pfx" 2>/dev/null | head -5)
    if [ -n "$P12_FILES" ]; then
        pass "Custom certificate(s) found:"
        echo "$P12_FILES" | while read -r f; do
            SUBJECT=$(openssl pkcs12 -in "$f" -passin pass: -nokeys 2>/dev/null | \
                openssl x509 -noout -subject 2>/dev/null || echo "  (password protected)")
            info "  $(basename "$f"): $SUBJECT"
        done
    else
        skip "No custom .p12/.pfx certificates in $CERT_DIR"
    fi
else
    skip "Certificate directory not found ($CERT_DIR)"
fi

echo ""

# =============================================================================
# TEST GROUP 5: End-to-End (--full only)
# =============================================================================

echo -e "${CYAN}── End-to-End Test ─────────────────────────────────────${NC}"

if [ "$FULL_TEST" = true ] && [ -n "$ADMIN_PASS" ]; then
    # Create a minimal test PDF
    TEST_PDF="/tmp/pdf-suite-test-input.pdf"
    SIGNED_PDF="/tmp/pdf-suite-test-signed.pdf"

    # Generate a minimal valid PDF
    cat > "$TEST_PDF" << 'PDFEOF'
%PDF-1.4
1 0 obj
<< /Type /Catalog /Pages 2 0 R >>
endobj
2 0 obj
<< /Type /Pages /Kids [3 0 R] /Count 1 >>
endobj
3 0 obj
<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Contents 4 0 R /Resources << >> >>
endobj
4 0 obj
<< /Length 44 >>
stream
BT /F1 12 Tf 100 700 Td (Test PDF) Tj ET
endstream
endobj
xref
0 5
0000000000 65535 f 
0000000009 00000 n 
0000000058 00000 n 
0000000115 00000 n 
0000000232 00000 n 
trailer
<< /Size 5 /Root 1 0 R >>
startxref
326
%%EOF
PDFEOF

    info "Created test PDF: $TEST_PDF"

    # 5.1 Upload + sign via API
    SIGN_RESPONSE=$(curl -s -o "$SIGNED_PDF" -w '%{http_code}' --max-time 30 \
        -X POST "$LOCAL_URL/api/v1/security/cert-sign" \
        -b /tmp/pdf-suite-cookies.txt \
        -F "fileInput=@$TEST_PDF" \
        -F "certType=server" \
        -F "reason=Validation Test" \
        -F "showSignature=true" \
        2>/dev/null || echo "000")

    if [ "$SIGN_RESPONSE" = "200" ]; then
        pass "PDF signed via API (HTTP $SIGN_RESPONSE)"

        # 5.2 Verify signed file is a valid PDF
        if head -c 5 "$SIGNED_PDF" 2>/dev/null | grep -q "%PDF"; then
            pass "Signed output is a valid PDF"
            SIGNED_SIZE=$(stat -f%z "$SIGNED_PDF" 2>/dev/null || stat -c%s "$SIGNED_PDF" 2>/dev/null || echo "?")
            info "Signed PDF size: ${SIGNED_SIZE} bytes"
        else
            fail "Signed output is not a valid PDF"
        fi
    else
        fail "PDF signing failed (HTTP $SIGN_RESPONSE)"
        info "This may require valid authentication — ensure --user and --pass are correct"
    fi

    # Cleanup
    rm -f "$TEST_PDF" "$SIGNED_PDF" /tmp/pdf-suite-cookies.txt
elif [ "$FULL_TEST" = true ]; then
    skip "End-to-end test requires --pass (admin password)"
else
    skip "End-to-end test (use --full --pass PASSWORD to run)"
fi

echo ""

# =============================================================================
# TEST GROUP 6: Port & Binding
# =============================================================================

echo -e "${CYAN}── Port & Binding ──────────────────────────────────────${NC}"

# 6.1 Port 8080 binding
BINDING=$(docker port "$CONTAINER_NAME" 8080 2>/dev/null || echo "none")
if echo "$BINDING" | grep -q "127.0.0.1"; then
    pass "Port 8080 bound to localhost only (secure)"
elif echo "$BINDING" | grep -q "0.0.0.0"; then
    warn "Port 8080 bound to 0.0.0.0 (publicly accessible — should be localhost only)"
else
    info "Port binding: $BINDING"
fi

# 6.2 Check port is not exposed beyond localhost
if command -v ss &>/dev/null; then
    LISTENING=$(ss -tlnp 2>/dev/null | grep ":8080" || echo "")
    if echo "$LISTENING" | grep -q "127.0.0.1"; then
        pass "Confirmed: port 8080 only listening on localhost"
    elif echo "$LISTENING" | grep -q "0.0.0.0\|:::"; then
        warn "Port 8080 may be publicly accessible"
    fi
fi

echo ""

# =============================================================================
# Summary
# =============================================================================

TOTAL=$((PASS_COUNT + FAIL_COUNT + WARN_COUNT + SKIP_COUNT))

echo -e "${CYAN}── Summary ─────────────────────────────────────────────${NC}"
echo ""
echo -e "  ${GREEN}$PASS_COUNT passed${NC}  ${RED}$FAIL_COUNT failed${NC}  ${YELLOW}$WARN_COUNT warnings${NC}  ${DIM}$SKIP_COUNT skipped${NC}  ($TOTAL total)"
echo ""

if [ "$FAIL_COUNT" -gt 0 ]; then
    echo -e "  ${RED}Some tests failed. Review the output above.${NC}"
    exit 1
elif [ "$WARN_COUNT" -gt 0 ]; then
    echo -e "  ${YELLOW}All critical tests passed with some warnings.${NC}"
    exit 0
else
    echo -e "  ${GREEN}All tests passed!${NC}"
    exit 0
fi
