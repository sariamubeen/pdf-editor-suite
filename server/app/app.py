"""
SIERA PDF - Web App
Bridges Windows clients with ONLYOFFICE Document Server.
Accepts PDF uploads, serves files, and renders the ONLYOFFICE editor.
Provides signature drawing/upload/type and PDF signing with visual placement.
"""

import os
import uuid
import json
import jwt
import time
import zipfile
import io
import base64
import logging
import urllib.request
from datetime import datetime
from werkzeug.utils import secure_filename
from flask import Flask, request, jsonify, send_from_directory, send_file, render_template
from PIL import Image

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 100 * 1024 * 1024  # 100MB max upload

logging.basicConfig(level=logging.INFO)

UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "/app/uploads")
SIGNATURE_DIR = os.environ.get("SIGNATURE_DIR", "/app/signatures")
JWT_SECRET = os.environ.get("JWT_SECRET", "pdfeditorsuite")
ONLYOFFICE_URL = os.environ.get("ONLYOFFICE_URL", "http://localhost:8443")
APP_URL = os.environ.get("APP_URL", "http://localhost:8080")

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(SIGNATURE_DIR, exist_ok=True)


def make_token(payload):
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def get_current_signature():
    """Return the current signature filename or None."""
    sigs = [f for f in os.listdir(SIGNATURE_DIR) if f.endswith(".png")]
    return sigs[0] if sigs else None


def process_signature_image(img_bytes):
    """Crop whitespace and make white background transparent."""
    img = Image.open(io.BytesIO(img_bytes)).convert("RGBA")
    data = list(img.getdata())
    # Make near-white pixels transparent
    new_data = []
    for r, g, b, a in data:
        if r > 235 and g > 235 and b > 235:
            new_data.append((r, g, b, 0))
        else:
            new_data.append((r, g, b, a))
    img.putdata(new_data)
    # Auto-crop to content
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
        # Add small padding
        padded = Image.new("RGBA", (img.width + 20, img.height + 20), (0, 0, 0, 0))
        padded.paste(img, (10, 10))
        img = padded
    buf = io.BytesIO()
    img.save(buf, "PNG")
    return buf.getvalue()


# ═══════════════════════════════════════════════════════════════════════════════
# Static files
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/logo.png")
def logo():
    return send_from_directory(os.path.join(os.path.dirname(__file__), "bundle"), "siera-logo.png")


@app.route("/static/<path:filename>")
def static_files(filename):
    return send_from_directory(os.path.join(os.path.dirname(__file__), "static"), filename)


# ═══════════════════════════════════════════════════════════════════════════════
# Homepage
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/")
def index():
    return """<!DOCTYPE html>
<html>
<head><title>SIERA PDF</title>
<style>
* { box-sizing: border-box; }
body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
       display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }
.box { text-align: center; padding: 48px; background: white; border-radius: 16px;
       box-shadow: 0 2px 16px rgba(0,0,0,0.08); max-width: 440px; width: 100%; }
.box img { height: 56px; margin-bottom: 8px; }
h1 { margin: 0 0 4px; font-size: 24px; }
.sub { color: #888; font-size: 13px; margin: 0 0 28px; }
.upload { border: 2px dashed #d0d0d0; padding: 40px 24px; border-radius: 10px; cursor: pointer;
          transition: all 0.15s; }
.upload:hover { border-color: #2563eb; background: #f0f6ff; }
.upload p { margin: 0; color: #888; font-size: 15px; }
input[type=file] { display: none; }
.links { margin-top: 28px; display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; }
.links a { color: #2563eb; text-decoration: none; font-size: 13px; font-weight: 500; }
.links a:hover { text-decoration: underline; }
#status { margin-top: 16px; font-size: 13px; color: #2563eb; }
</style></head>
<body>
<div class="box">
<img src="/logo.png" alt="SIERA PDF">
<h1>SIERA PDF</h1>
<p class="sub">Edit, annotate, and sign PDFs in your browser</p>
<div class="upload" onclick="document.getElementById('f').click()">
  <p>Click or drag a PDF here to edit</p>
  <input type="file" id="f" accept=".pdf" onchange="upload(this.files[0])">
</div>
<div id="status"></div>
<div class="links">
  <a href="/signature">My Signature</a>
  <a href="/sign">Sign a PDF</a>
  <a href="/download">Download Installer</a>
</div>
<div style="margin-top:32px;font-size:11px;color:#bbb">
  MIT License | ONLYOFFICE (AGPL-3.0) | pdf.js (Apache-2.0) |
  <a href="https://github.com/sariamubeen/pdf-editor-suite" target="_blank" style="color:#2563eb;text-decoration:none">GitHub</a>
</div>
</div>
<script>
function upload(file) {
  if (!file) return;
  document.getElementById('status').textContent = 'Uploading ' + file.name + '...';
  var fd = new FormData();
  fd.append('file', file);
  fetch('/api/upload', {method:'POST', body:fd})
  .then(function(r){return r.json()})
  .then(function(d){ window.location = d.url; })
  .catch(function(e){ document.getElementById('status').textContent = 'Error: ' + e; });
}
</script>
</body></html>"""


# ═══════════════════════════════════════════════════════════════════════════════
# PDF Upload & Edit (ONLYOFFICE)
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/api/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify(error="No file provided"), 400
    f = request.files["file"]
    if not f.filename.lower().endswith(".pdf"):
        return jsonify(error="Only PDF files are supported"), 400
    clean_name = secure_filename(f.filename) or "document.pdf"
    safe_name = f"{uuid.uuid4().hex[:8]}_{clean_name}"
    f.save(os.path.join(UPLOAD_DIR, safe_name))
    edit_url = f"{APP_URL}/edit/{safe_name}"
    return jsonify(url=edit_url, filename=safe_name)


@app.route("/files/<filename>")
def serve_file(filename):
    return send_from_directory(UPLOAD_DIR, filename)


@app.route("/edit/<filename>")
def edit(filename):
    filepath = os.path.join(UPLOAD_DIR, filename)
    if not os.path.exists(filepath):
        return "File not found", 404

    file_url = f"{APP_URL}/files/{filename}"
    callback_url = f"{APP_URL}/api/callback"

    config = {
        "document": {
            "fileType": "pdf",
            "key": uuid.uuid4().hex[:20],
            "title": filename.split("_", 1)[-1] if "_" in filename else filename,
            "url": file_url,
            "permissions": {"edit": True, "download": True, "print": True, "fillForms": True, "comment": True},
        },
        "documentType": "pdf",
        "height": "100%",
        "width": "100%",
        "editorConfig": {
            "callbackUrl": callback_url,
            "mode": "edit",
            "lang": "en",
            "user": {"id": "user1", "name": "User"},
            "customization": {"autosave": True, "forcesave": True, "compactHeader": False},
        },
    }

    token = make_token(config)
    config["token"] = token
    title = config["document"]["title"]
    config_json = json.dumps(config)

    return f"""<!DOCTYPE html>
<html style="height:100%;margin:0;padding:0;overflow:hidden">
<head><title>{title} - SIERA PDF</title>
<style>
.siera-bar {{
  position: relative; z-index: 99999;
  background: #16213e; height: 40px; display: flex; align-items: center;
  padding: 0 16px; gap: 12px; box-shadow: 0 2px 8px rgba(0,0,0,0.3);
  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  flex-shrink: 0;
}}
.siera-bar img {{ height: 22px; }}
.siera-bar span {{ color: #fff; font-size: 13px; font-weight: 500; }}
.siera-bar a {{
  color: #7ec8e3; text-decoration: none; font-size: 12px; padding: 4px 12px;
  border-radius: 4px; transition: all 0.15s;
}}
.siera-bar a:hover {{ background: rgba(255,255,255,0.1); color: #fff; }}
.siera-bar .sign-btn {{
  background: #2563eb; color: white !important; font-weight: 500;
  padding: 5px 14px; border-radius: 5px;
}}
.siera-bar .sign-btn:hover {{ background: #1d4ed8; }}
.siera-bar .spacer {{ flex: 1; }}
</style>
</head>
<body style="height:100%;margin:0;padding:0;overflow:hidden;display:flex;flex-direction:column">
<div class="siera-bar">
  <img src="/logo.png" alt="">
  <span>SIERA PDF</span>
  <div class="spacer"></div>
  <a href="/">Home</a>
  <a href="/signature" target="_blank">My Signature</a>
  <a href="/sign?file={filename}" class="sign-btn">Sign This PDF</a>
</div>
<div id="editor" style="flex:1;min-height:0"></div>
<script src="{ONLYOFFICE_URL}/web-apps/apps/api/documents/api.js"></script>
<script>new DocsAPI.DocEditor("editor", {config_json});</script>
</body></html>"""


@app.route("/api/callback", methods=["POST"])
def callback():
    data = request.json or {}
    status = data.get("status", 0)
    if status in (2, 6):
        download_url = data.get("url")
        key = data.get("key", "")
        if download_url:
            target = os.path.join(UPLOAD_DIR, f"saved_{key}.pdf")
            try:
                urllib.request.urlretrieve(download_url, target)
                logging.info(f"Callback: saved edited PDF to {target}")
            except Exception as e:
                logging.error(f"Callback: failed to save PDF: {e}")
    return jsonify(error=0)


# ═══════════════════════════════════════════════════════════════════════════════
# Signature Management
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/signature")
def signature_page():
    return render_template("signature.html")


@app.route("/api/signature/current")
def signature_current():
    sig = get_current_signature()
    if sig:
        return jsonify(url=f"/signatures/{sig}")
    return jsonify(url=None)


@app.route("/api/signature", methods=["POST"])
def save_signature():
    data = request.json or {}
    image_data = data.get("image", "")
    if not image_data.startswith("data:image/png;base64,"):
        return jsonify(ok=False, error="Invalid image data"), 400

    b64 = image_data.split(",", 1)[1]
    raw_bytes = base64.b64decode(b64)
    img_bytes = process_signature_image(raw_bytes)

    # Remove old signatures
    for fname in os.listdir(SIGNATURE_DIR):
        if fname.endswith(".png"):
            os.remove(os.path.join(SIGNATURE_DIR, fname))

    sig_file = f"signature_{uuid.uuid4().hex[:8]}.png"
    with open(os.path.join(SIGNATURE_DIR, sig_file), "wb") as fh:
        fh.write(img_bytes)

    return jsonify(ok=True, filename=sig_file)


@app.route("/api/signature/upload", methods=["POST"])
def upload_signature():
    if "file" not in request.files:
        return jsonify(ok=False, error="No file"), 400
    f = request.files["file"]
    if not f.content_type.startswith("image/"):
        return jsonify(ok=False, error="Not an image"), 400

    raw_bytes = f.read()
    processed = process_signature_image(raw_bytes)
    b64 = base64.b64encode(processed).decode("ascii")
    return jsonify(ok=True, image=f"data:image/png;base64,{b64}")


@app.route("/signatures/<filename>")
def serve_signature(filename):
    return send_from_directory(SIGNATURE_DIR, filename)


@app.route("/signature/delete", methods=["GET", "POST"])
def delete_signature():
    for fname in os.listdir(SIGNATURE_DIR):
        if fname.endswith(".png"):
            os.remove(os.path.join(SIGNATURE_DIR, fname))
    return """<script>window.location='/signature';</script>"""


# ═══════════════════════════════════════════════════════════════════════════════
# PDF Signing (visual placement)
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/sign")
def sign_page():
    return render_template("sign.html")


@app.route("/api/sign", methods=["POST"])
def sign_pdf():
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas as rl_canvas
    from reportlab.lib.utils import ImageReader

    if "file" not in request.files:
        return jsonify(error="No file"), 400
    pdf_file = request.files["file"]
    if not pdf_file.filename.lower().endswith(".pdf"):
        return jsonify(error="Only PDF files supported"), 400

    sig = get_current_signature()
    if not sig:
        return jsonify(error="No signature saved"), 400

    sig_path = os.path.join(SIGNATURE_DIR, sig)
    page_num = int(request.form.get("page", 1))
    x_pct = float(request.form.get("x_pct", 0.7))
    y_pct = float(request.form.get("y_pct", 0.85))
    w_pct = float(request.form.get("w_pct", 0.2))
    h_pct = float(request.form.get("h_pct", 0.08))
    add_date = request.form.get("add_date", "0") == "1"

    tmp_pdf = os.path.join(UPLOAD_DIR, f"sign_input_{uuid.uuid4().hex[:8]}.pdf")
    pdf_file.save(tmp_pdf)

    try:
        reader = PdfReader(tmp_pdf)
        writer = PdfWriter()
        target_page_idx = page_num - 1  # 0-indexed

        for i, page in enumerate(reader.pages):
            if i == target_page_idx:
                page_w = float(page.mediabox.width)
                page_h = float(page.mediabox.height)

                # Convert percentages to PDF coordinates
                # Note: PDF y-axis is bottom-up, browser y-axis is top-down
                sig_w = w_pct * page_w
                sig_h = h_pct * page_h
                sig_x = x_pct * page_w
                sig_y = page_h - (y_pct * page_h) - sig_h  # flip Y

                # Create overlay
                overlay_buf = io.BytesIO()
                c = rl_canvas.Canvas(overlay_buf, pagesize=(page_w, page_h))
                c.drawImage(ImageReader(sig_path), sig_x, sig_y, sig_w, sig_h, mask="auto")

                # Add date text below signature
                if add_date:
                    date_str = datetime.now().strftime("%Y-%m-%d")
                    c.setFont("Helvetica", 8)
                    c.setFillColorRGB(0.3, 0.3, 0.3)
                    c.drawString(sig_x, sig_y - 12, date_str)

                c.save()
                overlay_buf.seek(0)
                overlay_page = PdfReader(overlay_buf).pages[0]
                page.merge_page(overlay_page)

            writer.add_page(page)

        output_buf = io.BytesIO()
        writer.write(output_buf)
        output_buf.seek(0)

        return send_file(
            output_buf, mimetype="application/pdf", as_attachment=True,
            download_name=f"signed_{secure_filename(pdf_file.filename) or 'document.pdf'}"
        )
    finally:
        if os.path.exists(tmp_pdf):
            os.remove(tmp_pdf)


# ═══════════════════════════════════════════════════════════════════════════════
# Download installer & Health
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/download")
def download():
    buf = io.BytesIO()
    bundle_dir = os.path.join(os.path.dirname(__file__), "bundle")
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        for fname in ("INSTALL.bat", "PDF-Editor-Suite-Client-Guide.html", "UNINSTALL.bat"):
            path = os.path.join(bundle_dir, fname)
            if os.path.exists(path):
                zf.write(path, fname)
    buf.seek(0)
    return send_file(buf, mimetype="application/zip", as_attachment=True, download_name="SIERA-PDF-Setup.zip")


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
