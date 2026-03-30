# Digital Signature Certificate Guide

## Overview

Stirling-PDF supports two types of digital signatures:

| Type | Use Case | Tamper-Evident | Org Identity |
|------|----------|----------------|--------------|
| **Handwritten / Image** | Quick signing of forms, letters | No | No |
| **Certificate (X.509)** | Legal documents, contracts, compliance | ✅ Yes | ✅ Yes |

This guide covers **certificate-based signatures** which are tamper-evident
and embed your organization's identity into the PDF.

---

## Option A: Auto-Generated Server Certificate (Default)

The `docker-compose.yml` enables this by default:

```yaml
SYSTEM_SERVERCERTIFICATE_ENABLED=true
SYSTEM_SERVERCERTIFICATE_ORGANIZATIONNAME=My Organization
SYSTEM_SERVERCERTIFICATE_VALIDITY=365
```

When signing a PDF, select **Server certificate** in Stirling-PDF.

**Pros:** Zero setup, works immediately.
**Cons:** Self-signed — PDF readers will show "signature validity unknown"
(the signature still proves the document hasn't been modified).

---

## Option B: Custom Organization Certificate

Run the included generator:

```bash
cd server/
chmod +x generate-cert.sh
./generate-cert.sh
```

You'll be prompted for:
- Organization name
- Common name
- Country code
- Validity period
- PKCS#12 password

The certificate is saved to `server/data/certs/signing.p12`.

### Using the Custom Certificate

1. Open Stirling-PDF → **Security → Certificate Signing**
2. Upload your PDF
3. Select **Custom certificate**
4. Upload `signing.p12`
5. Enter the password
6. Set signing reason and location
7. Click **Sign**

---

## Option C: Commercially Trusted Certificate

For signatures that show as "valid" in Adobe Reader without manual trust:

1. Purchase a document signing certificate from a CA on [Adobe's AATL](https://helpx.adobe.com/acrobat/kb/approved-trust-list1.html) (e.g., DigiCert, GlobalSign, Sectigo)
2. Export it as a `.p12` / `.pfx` file
3. Place it in `server/data/certs/`
4. Use it via the **Custom certificate** option in Stirling-PDF

---

## Updating / Rotating Certificates

### Regenerate auto-generated cert
```bash
# In docker-compose.yml, temporarily set:
# SYSTEM_SERVERCERTIFICATE_REGENERATEONSTARTUP=true
docker compose restart stirling-pdf
# Then set it back to false
```

### Replace custom cert
```bash
# Generate a new one
./generate-cert.sh

# Restart is not required — custom certs are uploaded per-signing
```

### Certificate expiry
Auto-generated certs expire based on `VALIDITY` (default: 365 days).
Set a calendar reminder to regenerate before expiry.

---

## Validating Signed PDFs

### In Stirling-PDF
- Go to **Security → Validate Signature**
- Upload the signed PDF
- View signer details, trust chain, and modification status

### Via API
```bash
curl -X POST https://pdf.yourdomain.com/api/v1/security/validate-signature \
  -F "fileInput=@signed-document.pdf"
```

### In Adobe Reader
- Open the signed PDF
- Click the signature panel
- If using a self-signed cert, you'll need to add it to trusted identities
