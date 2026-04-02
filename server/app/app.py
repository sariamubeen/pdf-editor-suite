"""
SIERA PDF - Web App (Multi-User)
PDF editor with ONLYOFFICE, signature drawing/upload/type, visual PDF signing.
Per-user file storage and signatures with simple name+email login.
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
from functools import wraps
from werkzeug.utils import secure_filename
from flask import Flask, request, jsonify, send_from_directory, send_file, render_template, session, redirect, g
from PIL import Image
from db import init_db, get_user_by_email, create_user, get_user_by_id

app = Flask(__name__)
app.config["MAX_CONTENT_LENGTH"] = 100 * 1024 * 1024  # 100MB
app.secret_key = os.environ.get("SESSION_SECRET", "change-me-in-production-xyz")

logging.basicConfig(level=logging.INFO)

UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "/app/uploads")
SIGNATURE_DIR = os.environ.get("SIGNATURE_DIR", "/app/signatures")
JWT_SECRET = os.environ.get("JWT_SECRET", "pdfeditorsuite")
ONLYOFFICE_URL = os.environ.get("ONLYOFFICE_URL", "http://localhost:8443")
APP_URL = os.environ.get("APP_URL", "http://localhost:8080")
APP_NAME = os.environ.get("APP_NAME", "SIERA PDF")
APP_SHORTNAME = os.environ.get("APP_SHORTNAME", "SieraPDF")
APP_LOGO = os.environ.get("APP_LOGO", "siera-logo.png")

os.makedirs(UPLOAD_DIR, exist_ok=True)
os.makedirs(SIGNATURE_DIR, exist_ok=True)

# Initialize database on startup
init_db()


# ═══════════════════════════════════════════════════════════════════════════════
# Auth helpers
# ═══════════════════════════════════════════════════════════════════════════════

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        user_id = session.get("user_id")
        if not user_id:
            return redirect(f"/login?next={request.path}")
        user = get_user_by_id(user_id)
        if not user:
            session.clear()
            return redirect("/login")
        g.user = user
        return f(*args, **kwargs)
    return decorated


@app.before_request
def load_user():
    g.user = None
    user_id = session.get("user_id")
    if user_id:
        g.user = get_user_by_id(user_id)


def user_upload_dir(user_id):
    d = os.path.join(UPLOAD_DIR, str(user_id))
    os.makedirs(d, exist_ok=True)
    return d


def user_signature_dir(user_id):
    d = os.path.join(SIGNATURE_DIR, str(user_id))
    os.makedirs(d, exist_ok=True)
    return d


def get_current_signature(user_id):
    sig_dir = user_signature_dir(user_id)
    sigs = [f for f in os.listdir(sig_dir) if f.endswith(".png")]
    return sigs[0] if sigs else None


def make_token(payload):
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


def process_signature_image(img_bytes):
    img = Image.open(io.BytesIO(img_bytes)).convert("RGBA")
    data = list(img.getdata())
    new_data = [(r, g_, b, 0) if r > 235 and g_ > 235 and b > 235 else (r, g_, b, a) for r, g_, b, a in data]
    img.putdata(new_data)
    bbox = img.getbbox()
    if bbox:
        img = img.crop(bbox)
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
    return send_from_directory(os.path.join(os.path.dirname(__file__), "bundle"), APP_LOGO)


@app.route("/icon.ico")
def icon():
    return send_from_directory(os.path.join(os.path.dirname(__file__), "bundle"), "siera.ico")


@app.route("/static/<path:filename>")
def static_files(filename):
    return send_from_directory(os.path.join(os.path.dirname(__file__), "static"), filename)


# ═══════════════════════════════════════════════════════════════════════════════
# Login / Logout
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/login", methods=["GET", "POST"])
def login():
    if request.method == "GET":
        if session.get("user_id"):
            return redirect("/")
        return render_template("login.html", APP_NAME=APP_NAME, next=request.args.get("next", "/"))

    name = (request.form.get("name") or "").strip()
    email = (request.form.get("email") or "").strip().lower()

    if not name or not email or "@" not in email:
        return render_template("login.html", APP_NAME=APP_NAME, error="Please enter your name and a valid email.",
                               next=request.form.get("next", "/"))

    user = get_user_by_email(email)
    if not user:
        user = create_user(name, email)

    session["user_id"] = user["id"]
    session["user_name"] = user["name"]
    session.permanent = True

    next_url = request.args.get("next") or request.form.get("next") or "/"
    return redirect(next_url)


@app.route("/logout")
def logout():
    session.clear()
    return redirect("/login")


# ═══════════════════════════════════════════════════════════════════════════════
# Homepage
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/")
@login_required
def index():
    user = g.user
    return f"""<!DOCTYPE html>
<html>
<head><title>{APP_NAME}</title>
<style>
* {{ box-sizing: border-box; }}
body {{ font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
       display: flex; justify-content: center; align-items: center; height: 100vh; margin: 0; background: #f5f5f5; }}
.box {{ text-align: center; padding: 48px; background: white; border-radius: 16px;
       box-shadow: 0 2px 16px rgba(0,0,0,0.08); max-width: 440px; width: 100%; }}
.box img {{ height: 56px; margin-bottom: 8px; }}
h1 {{ margin: 0 0 4px; font-size: 24px; }}
.sub {{ color: #888; font-size: 13px; margin: 0 0 28px; }}
.upload {{ border: 2px dashed #d0d0d0; padding: 40px 24px; border-radius: 10px; cursor: pointer;
          transition: all 0.15s; }}
.upload:hover {{ border-color: #2563eb; background: #f0f6ff; }}
.upload p {{ margin: 0; color: #888; font-size: 15px; }}
input[type=file] {{ display: none; }}
.links {{ margin-top: 28px; display: flex; justify-content: center; gap: 20px; flex-wrap: wrap; }}
.links a {{ color: #2563eb; text-decoration: none; font-size: 13px; font-weight: 500; }}
.links a:hover {{ text-decoration: underline; }}
#status {{ margin-top: 16px; font-size: 13px; color: #2563eb; }}
.user-bar {{ margin-bottom: 20px; font-size: 13px; color: #666; }}
.user-bar a {{ color: #ef4444; text-decoration: none; margin-left: 8px; }}
</style></head>
<body>
<div class="box">
<img src="/logo.png" alt="{APP_NAME}">
<h1>{APP_NAME}</h1>
<div class="user-bar">Welcome, {user['name']} <a href="/logout">Logout</a></div>
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
<div style="margin-top:40px;padding-top:20px;border-top:1px solid #eee;font-size:11px;color:#bbb">
  Powered by <a href="https://github.com/sariamubeen/pdf-editor-suite" target="_blank" style="color:#999;text-decoration:none">pdf-editor-suite</a>
</div>
</div>
<script>
function upload(file) {{
  if (!file) return;
  document.getElementById('status').textContent = 'Uploading ' + file.name + '...';
  var fd = new FormData();
  fd.append('file', file);
  fetch('/api/upload', {{method:'POST', body:fd}})
  .then(function(r){{return r.json()}})
  .then(function(d){{ window.location = d.url; }})
  .catch(function(e){{ document.getElementById('status').textContent = 'Error: ' + e; }});
}}
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

    user_id = session.get("user_id")
    if user_id:
        target_dir = user_upload_dir(user_id)
        path_prefix = str(user_id)
    else:
        target_dir = os.path.join(UPLOAD_DIR, "anonymous")
        os.makedirs(target_dir, exist_ok=True)
        path_prefix = "anonymous"

    f.save(os.path.join(target_dir, safe_name))
    edit_url = f"{APP_URL}/edit/{path_prefix}/{safe_name}"
    return jsonify(url=edit_url, filename=safe_name)


@app.route("/files/<path_prefix>/<filename>")
def serve_file(path_prefix, filename):
    return send_from_directory(os.path.join(UPLOAD_DIR, path_prefix), filename)


# Legacy route for old URLs
@app.route("/files/<filename>")
def serve_file_legacy(filename):
    return send_from_directory(UPLOAD_DIR, filename)


@app.route("/edit/<path_prefix>/<filename>")
@login_required
def edit(path_prefix, filename):
    filepath = os.path.join(UPLOAD_DIR, path_prefix, filename)
    if not os.path.exists(filepath):
        return "File not found", 404

    file_url = f"{APP_URL}/files/{path_prefix}/{filename}"
    callback_url = f"{APP_URL}/api/callback"
    user = g.user

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
            "user": {"id": str(user["id"]), "name": user["name"]},
            "customization": {"autosave": True, "forcesave": True, "compactHeader": False},
        },
    }

    token = make_token(config)
    config["token"] = token
    title = config["document"]["title"]
    config_json = json.dumps(config)

    return f"""<!DOCTYPE html>
<html style="height:100%;margin:0;padding:0;overflow:hidden">
<head><title>{title} - {APP_NAME}</title>
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
.siera-bar .user {{ color: #7ec8e3; font-size: 12px; }}
</style>
</head>
<body style="height:100%;margin:0;padding:0;overflow:hidden;display:flex;flex-direction:column">
<div class="siera-bar">
  <img src="/logo.png" alt="">
  <span>{APP_NAME}</span>
  <div class="spacer"></div>
  <span class="user">{user['name']}</span>
  <a href="/">Home</a>
  <a href="/signature" target="_blank">My Signature</a>
  <a href="/sign?file={path_prefix}/{filename}" class="sign-btn">Sign This PDF</a>
</div>
<div id="editor" style="flex:1;min-height:0"></div>
<script src="{ONLYOFFICE_URL}/web-apps/apps/api/documents/api.js"></script>
<script>new DocsAPI.DocEditor("editor", {config_json});</script>
</body></html>"""


# Legacy edit route
@app.route("/edit/<filename>")
@login_required
def edit_legacy(filename):
    filepath = os.path.join(UPLOAD_DIR, filename)
    if os.path.exists(filepath):
        return edit("anonymous", filename)
    return "File not found", 404


@app.route("/api/callback", methods=["POST"])
def callback():
    data = request.json or {}
    status = data.get("status", 0)
    if status in (2, 6):
        download_url = data.get("url")
        key = data.get("key", "")
        if download_url:
            callbacks_dir = os.path.join(UPLOAD_DIR, "callbacks")
            os.makedirs(callbacks_dir, exist_ok=True)
            target = os.path.join(callbacks_dir, f"saved_{key}.pdf")
            try:
                urllib.request.urlretrieve(download_url, target)
                logging.info(f"Callback: saved to {target}")
            except Exception as e:
                logging.error(f"Callback: failed: {e}")
    return jsonify(error=0)


# ═══════════════════════════════════════════════════════════════════════════════
# Signature Management (per-user)
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/signature")
@login_required
def signature_page():
    return render_template("signature.html", APP_NAME=APP_NAME, user=g.user)


@app.route("/api/signature/current")
@login_required
def signature_current():
    sig = get_current_signature(g.user["id"])
    if sig:
        return jsonify(url=f"/signatures/{g.user['id']}/{sig}")
    return jsonify(url=None)


@app.route("/api/signature", methods=["POST"])
@login_required
def save_signature():
    data = request.json or {}
    image_data = data.get("image", "")
    if not image_data.startswith("data:image/png;base64,"):
        return jsonify(ok=False, error="Invalid image data"), 400

    b64 = image_data.split(",", 1)[1]
    raw_bytes = base64.b64decode(b64)
    img_bytes = process_signature_image(raw_bytes)

    sig_dir = user_signature_dir(g.user["id"])
    for fname in os.listdir(sig_dir):
        if fname.endswith(".png"):
            os.remove(os.path.join(sig_dir, fname))

    sig_file = f"signature_{uuid.uuid4().hex[:8]}.png"
    with open(os.path.join(sig_dir, sig_file), "wb") as fh:
        fh.write(img_bytes)

    return jsonify(ok=True, filename=sig_file)


@app.route("/api/signature/upload", methods=["POST"])
@login_required
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


@app.route("/signatures/<int:user_id>/<filename>")
def serve_signature(user_id, filename):
    return send_from_directory(user_signature_dir(user_id), filename)


@app.route("/signature/delete", methods=["GET", "POST"])
@login_required
def delete_signature():
    sig_dir = user_signature_dir(g.user["id"])
    for fname in os.listdir(sig_dir):
        if fname.endswith(".png"):
            os.remove(os.path.join(sig_dir, fname))
    return """<script>window.location='/signature';</script>"""


# ═══════════════════════════════════════════════════════════════════════════════
# PDF Signing (per-user signature)
# ═══════════════════════════════════════════════════════════════════════════════

@app.route("/sign")
@login_required
def sign_page():
    return render_template("sign.html", APP_NAME=APP_NAME, user=g.user)


@app.route("/api/sign", methods=["POST"])
@login_required
def sign_pdf():
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas as rl_canvas
    from reportlab.lib.utils import ImageReader

    if "file" not in request.files:
        return jsonify(error="No file"), 400
    pdf_file = request.files["file"]
    if not pdf_file.filename.lower().endswith(".pdf"):
        return jsonify(error="Only PDF files supported"), 400

    sig = get_current_signature(g.user["id"])
    if not sig:
        return jsonify(error="No signature saved"), 400

    sig_path = os.path.join(user_signature_dir(g.user["id"]), sig)
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
        target_page_idx = page_num - 1

        for i, page in enumerate(reader.pages):
            if i == target_page_idx:
                page_w = float(page.mediabox.width)
                page_h = float(page.mediabox.height)
                sig_w = w_pct * page_w
                sig_h = h_pct * page_h
                sig_x = x_pct * page_w
                sig_y = page_h - (y_pct * page_h) - sig_h

                overlay_buf = io.BytesIO()
                c = rl_canvas.Canvas(overlay_buf, pagesize=(page_w, page_h))
                c.drawImage(ImageReader(sig_path), sig_x, sig_y, sig_w, sig_h, mask="auto")

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

def generate_install_bat():
    return f"""@echo off
setlocal
cd /d "%~dp0"
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Requesting Administrator privileges...
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)
cd /d "%~dp0"
title {APP_NAME} - Installer
echo.
echo   +==========================================================+
echo   ^|  {APP_NAME} - Installer{' ' * max(0, 42 - len(APP_NAME))}^|
echo   +==========================================================+
echo.
set "SERVER_URL={APP_URL}"
echo   Server: %SERVER_URL%
echo.
set "INSTDIR=%ProgramFiles%\\{APP_SHORTNAME}"
set "PROGID={APP_SHORTNAME}.PDF"
set "APPNAME={APP_NAME}"
set "BATPATH=%INSTDIR%\\open-pdf.bat"
echo   [1/6] Creating install directory...
if not exist "%INSTDIR%" mkdir "%INSTDIR%"
if not exist "%INSTDIR%" (echo         ERROR: Cannot create %INSTDIR% & goto :done)
echo         OK: %INSTDIR%
echo   [2/6] Creating scripts...
>"%INSTDIR%\\open-pdf.bat" (
echo @echo off
echo powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%%~dp0Open-PDFInBrowser.ps1" "%%~1"
)
echo         OK: open-pdf.bat
>"%INSTDIR%\\config.ps1" (
echo $PDFEditorURL = "%SERVER_URL%"
echo $RequireLogin = $false
echo $InstallDir = "$env:ProgramFiles\\{APP_SHORTNAME}"
echo $ProgId = "%PROGID%"
echo $DisplayName = "%APPNAME%"
)
echo         OK: config.ps1
set "B64=%temp%\\{APP_SHORTNAME.lower()}_handler.b64"
set "TARGET=%INSTDIR%\\Open-PDFInBrowser.ps1"
>"%B64%" echo cGFyYW0oW1BhcmFtZXRlcihNYW5kYXRvcnk9JHRydWUsUG9zaXRpb249MCldW3N0cmluZ10kUGRmUGF0aCkKCiRsb2dGaWxlID0gSm9pbi1QYXRoIChbU3lzdGVtLklPLlBhdGhdOjpHZXRUZW1wUGF0aCgpKSAiU2llcmFQREYtZGVidWcubG9nIgpmdW5jdGlvbiBMb2coJG1zZykgewogICAgJHRzID0gR2V0LURhdGUgLUZvcm1hdCAieXl5eS1NTS1kZCBISDptbTpzcyIKICAgICIkdHMgICRtc2ciIHwgT3V0LUZpbGUgLUFwcGVuZCAtRmlsZVBhdGggJGxvZ0ZpbGUgLUVuY29kaW5nIFVURjgKfQoKTG9nICI9PT0gU0lFUkEgUERGIEhhbmRsZXIgc3RhcnRlZCA9PT0iCkxvZyAiUGRmUGF0aDogJFBkZlBhdGgiCgouIChKb2luLVBhdGggKFNwbGl0LVBhdGggLVBhcmVudCAkTXlJbnZvY2F0aW9uLk15Q29tbWFuZC5EZWZpbml0aW9uKSAiY29uZmlnLnBzMSIpCkxvZyAiU2VydmVyOiAkUERGRWRpdG9yVVJMIgoKaWYgKC1ub3QgKFRlc3QtUGF0aCAtTGl0ZXJhbFBhdGggJFBkZlBhdGgpKSB7CiAgICBMb2cgIkVSUk9SOiBGaWxlIG5vdCBmb3VuZDogJFBkZlBhdGgiCiAgICBleGl0IDEKfQokUGRmUGF0aCA9IChSZXNvbHZlLVBhdGggLUxpdGVyYWxQYXRoICRQZGZQYXRoKS5QYXRoCiRGaWxlTmFtZSA9IFtTeXN0ZW0uSU8uUGF0aF06OkdldEZpbGVOYW1lKCRQZGZQYXRoKQpMb2cgIkZpbGU6ICRQZGZQYXRoIgoKdHJ5IHsKICAgIExvZyAiVXBsb2FkaW5nIHRvICRQREZFZGl0b3JVUkwvYXBpL3VwbG9hZCAuLi4iCiAgICBBZGQtVHlwZSAtQXNzZW1ibHlOYW1lIFN5c3RlbS5OZXQuSHR0cAogICAgJGNsaWVudCA9IE5ldy1PYmplY3QgU3lzdGVtLk5ldC5IdHRwLkh0dHBDbGllbnQKICAgICRjb250ZW50ID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHAuTXVsdGlwYXJ0Rm9ybURhdGFDb250ZW50CiAgICAkZmlsZVN0cmVhbSA9IFtTeXN0ZW0uSU8uRmlsZV06Ok9wZW5SZWFkKCRQZGZQYXRoKQogICAgJGZpbGVDb250ZW50ID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHAuU3RyZWFtQ29udGVudCgkZmlsZVN0cmVhbSkKICAgICRmaWxlQ29udGVudC5IZWFkZXJzLkNvbnRlbnRUeXBlID0gTmV3LU9iamVjdCBTeXN0ZW0uTmV0Lkh0dHAuSGVhZGVycy5NZWRpYVR5cGVIZWFkZXJWYWx1ZSgiYXBwbGljYXRpb24vcGRmIikKICAgICRjb250ZW50LkFkZCgkZmlsZUNvbnRlbnQsICJmaWxlIiwgJEZpbGVOYW1lKQogICAgJHJlc3BvbnNlID0gJGNsaWVudC5Qb3N0QXN5bmMoIiRQREZFZGl0b3JVUkwvYXBpL3VwbG9hZCIsICRjb250ZW50KS5SZXN1bHQKICAgICRib2R5ID0gJHJlc3BvbnNlLkNvbnRlbnQuUmVhZEFzU3RyaW5nQXN5bmMoKS5SZXN1bHQKICAgICRmaWxlU3RyZWFtLkNsb3NlKCkKICAgICRjbGllbnQuRGlzcG9zZSgpCiAgICBMb2cgIlJlc3BvbnNlOiAkKCRyZXNwb25zZS5TdGF0dXNDb2RlKSAtICRib2R5IgogICAgJGpzb24gPSAkYm9keSB8IENvbnZlcnRGcm9tLUpzb24KICAgICRlZGl0VXJsID0gJGpzb24udXJsCiAgICBMb2cgIkVkaXQgVVJMOiAkZWRpdFVybCIKICAgIFN0YXJ0LVByb2Nlc3MgJGVkaXRVcmwKICAgIExvZyAiQnJvd3NlciBvcGVuZWQiCn0gY2F0Y2ggewogICAgTG9nICJFUlJPUjogJCgkXy5FeGNlcHRpb24uTWVzc2FnZSkiCiAgICBTdGFydC1Qcm9jZXNzICIkUERGRWRpdG9yVVJMIgp9CgpMb2cgIj09PSBTSUVSQSBQREYGSW5kbGVyIGZpbmlzaGVkID09PSIKZXhpdCAwCg==
certutil -decode "%B64%" "%TARGET%" >nul 2>&1
del /q "%B64%" >nul 2>&1
if not exist "%TARGET%" (echo         ERROR: Failed to create handler & goto :done)
echo         OK: Open-PDFInBrowser.ps1
:: Download icon from server
echo   Downloading app icon...
powershell -NoProfile -ExecutionPolicy Bypass -Command "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12; Invoke-WebRequest -Uri '{APP_URL}/icon.ico' -OutFile ('%INSTDIR%' + '\\app.ico') -UseBasicParsing -TimeoutSec 10"
if exist "%INSTDIR%\\app.ico" (echo         OK: Icon downloaded) else (echo         WARN: Icon download failed - using default)
echo   [3/6] Registering file handler...
reg add "HKLM\\SOFTWARE\\Classes\\%PROGID%" /ve /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\Classes\\%PROGID%" /v "FriendlyTypeName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\Classes\\%PROGID%\\DefaultIcon" /ve /d "%INSTDIR%\\app.ico,0" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\Classes\\%PROGID%\\shell\\open\\command" /ve /d "\\"%BATPATH%\\" \\"%%1\\"" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\Classes\\Applications\\open-pdf.bat" /v "FriendlyAppName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\Classes\\Applications\\open-pdf.bat\\DefaultIcon" /ve /d "%INSTDIR%\\app.ico,0" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\Classes\\Applications\\open-pdf.bat\\shell\\open\\command" /ve /d "\\"%BATPATH%\\" \\"%%1\\"" /f >nul 2>&1
set "CUR="
for /f "tokens=2*" %%a in ('reg query "HKLM\\SOFTWARE\\Classes\\.pdf" /ve 2^>nul ^| find "REG_SZ"') do set "CUR=%%b"
if defined CUR (if not "%CUR%"=="%PROGID%" (reg add "HKLM\\SOFTWARE\\Classes\\.pdf" /v "{APP_SHORTNAME}_PreviousHandler" /d "%CUR%" /f >nul 2>&1 & echo         Backed up: %CUR%))
reg add "HKLM\\SOFTWARE\\Classes\\.pdf" /ve /d "%PROGID%" /f >nul 2>&1
ftype %PROGID%="%BATPATH%" "%%1" >nul 2>&1
assoc .pdf=%PROGID% >nul 2>&1
echo         OK: .pdf handler registered
echo   [4/6] Setting as default PDF app...
reg add "HKLM\\SOFTWARE\\Classes\\.pdf\\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\{APP_SHORTNAME}\\Capabilities" /v "ApplicationName" /d "%APPNAME%" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\{APP_SHORTNAME}\\Capabilities" /v "ApplicationDescription" /d "{APP_NAME} - PDF Editor" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\{APP_SHORTNAME}\\Capabilities\\FileAssociations" /v ".pdf" /d "%PROGID%" /f >nul 2>&1
reg add "HKLM\\SOFTWARE\\RegisteredApplications" /v "{APP_SHORTNAME}" /d "SOFTWARE\\{APP_SHORTNAME}\\Capabilities" /f >nul 2>&1
reg delete "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\UserChoice" /f >nul 2>&1
reg add "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\OpenWithProgids" /v "%PROGID%" /t REG_NONE /f >nul 2>&1
echo         OK: Default app set
echo   [5/6] Creating uninstaller...
>"%INSTDIR%\\Uninstall.bat" (
echo @echo off
echo net session ^>nul 2^>^&1
echo if %%errorlevel%% neq 0 ^(powershell -Command "Start-Process '%%~f0' -Verb RunAs" ^& exit /b^)
echo echo Uninstalling {APP_NAME}...
echo reg delete "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\UserChoice" /f ^>nul 2^>^&1
echo reg delete "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\OpenWithProgids" /v "{APP_SHORTNAME}.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\\SOFTWARE\\Classes\\.pdf\\OpenWithProgids" /v "{APP_SHORTNAME}.PDF" /f ^>nul 2^>^&1
echo reg delete "HKLM\\SOFTWARE\\{APP_SHORTNAME}" /f ^>nul 2^>^&1
echo reg delete "HKLM\\SOFTWARE\\RegisteredApplications" /v "{APP_SHORTNAME}" /f ^>nul 2^>^&1
echo reg delete "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" /v "DefaultAssociationsConfiguration" /f ^>nul 2^>^&1
echo reg delete "HKLM\\SOFTWARE\\Classes\\{APP_SHORTNAME}.PDF" /f ^>nul 2^>^&1
echo ftype {APP_SHORTNAME}.PDF= ^>nul 2^>^&1
echo echo [OK] Removed
echo rmdir /s /q "%%ProgramFiles%%\\{APP_SHORTNAME}" 2^>nul
echo echo {APP_NAME} has been uninstalled.
echo pause
)
echo         OK: Uninstaller created
:: Rebuild Windows icon cache
echo   Refreshing icon cache (explorer will restart)...
ie4uinit.exe -show >nul 2>&1
taskkill /f /im explorer.exe >nul 2>&1
del /f /s /q "%LocalAppData%\\IconCache.db" >nul 2>&1
del /f /s /q "%LocalAppData%\\Microsoft\\Windows\\Explorer\\iconcache*" >nul 2>&1
start explorer.exe
timeout /t 2 >nul
echo   [6/6] Validating...
set "FAIL=0"
if exist "%INSTDIR%\\config.ps1" (echo         [OK] config.ps1) else (echo         [!!] config.ps1 & set "FAIL=1")
if exist "%INSTDIR%\\Open-PDFInBrowser.ps1" (echo         [OK] Open-PDFInBrowser.ps1) else (echo         [!!] Open-PDFInBrowser.ps1 & set "FAIL=1")
if exist "%INSTDIR%\\open-pdf.bat" (echo         [OK] open-pdf.bat) else (echo         [!!] open-pdf.bat & set "FAIL=1")
reg query "HKLM\\SOFTWARE\\Classes\\%PROGID%" >nul 2>&1
if %errorlevel% equ 0 (echo         [OK] Registry) else (echo         [!!] Registry & set "FAIL=1")
echo.
if "%FAIL%"=="0" (
    echo   +==========================================================+
    echo   ^|  {APP_NAME} - Setup Complete!{' ' * max(0, 36 - len(APP_NAME))}^|
    echo   ^|  Double-click any .pdf or use Open with ^> {APP_NAME}{' ' * max(0, 15 - len(APP_NAME))}^|
    echo   ^|  Server: %SERVER_URL%
    echo   ^|  Uninstall: %INSTDIR%\\Uninstall.bat
    echo   +==========================================================+
) else (echo   Setup had errors. Review output above.)
:done
echo.
pause
endlocal
"""


def generate_uninstall_bat():
    return f"""@echo off
setlocal
cd /d "%~dp0"
net session >nul 2>&1
if %errorlevel% neq 0 (powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs" & exit /b)
cd /d "%~dp0"
title {APP_NAME} - Uninstaller
echo.
echo   Uninstalling {APP_NAME}...
echo.
set "INSTDIR=%ProgramFiles%\\{APP_SHORTNAME}"
set "PROGID={APP_SHORTNAME}.PDF"
set "PREV="
for /f "tokens=2*" %%a in ('reg query "HKLM\\SOFTWARE\\Classes\\.pdf" /v "{APP_SHORTNAME}_PreviousHandler" 2^>nul ^| find "REG_SZ"') do set "PREV=%%b"
if defined PREV (reg add "HKLM\\SOFTWARE\\Classes\\.pdf" /ve /d "%PREV%" /f >nul 2>&1 & reg delete "HKLM\\SOFTWARE\\Classes\\.pdf" /v "{APP_SHORTNAME}_PreviousHandler" /f >nul 2>&1 & echo   [OK] Restored previous handler) else (reg add "HKLM\\SOFTWARE\\Classes\\.pdf" /ve /d "" /f >nul 2>&1)
reg delete "HKLM\\SOFTWARE\\Classes\\%PROGID%" /f >nul 2>&1
ftype %PROGID%= >nul 2>&1
reg delete "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\UserChoice" /f >nul 2>&1
reg delete "HKCU\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Explorer\\FileExts\\.pdf\\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\\SOFTWARE\\Classes\\.pdf\\OpenWithProgids" /v "%PROGID%" /f >nul 2>&1
reg delete "HKLM\\SOFTWARE\\{APP_SHORTNAME}" /f >nul 2>&1
reg delete "HKLM\\SOFTWARE\\RegisteredApplications" /v "{APP_SHORTNAME}" /f >nul 2>&1
reg delete "HKLM\\SOFTWARE\\Policies\\Microsoft\\Windows\\System" /v "DefaultAssociationsConfiguration" /f >nul 2>&1
echo   [OK] Registry cleaned
if exist "%INSTDIR%" (rmdir /s /q "%INSTDIR%" & echo   [OK] Files removed)
echo.
echo   {APP_NAME} has been uninstalled.
echo.
pause
endlocal
"""


@app.route("/download")
def download():
    buf = io.BytesIO()
    bundle_dir = os.path.join(os.path.dirname(__file__), "bundle")
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        zf.writestr("INSTALL.bat", generate_install_bat())
        zf.writestr("UNINSTALL.bat", generate_uninstall_bat())
        guide_path = os.path.join(bundle_dir, "PDF-Editor-Suite-Client-Guide.html")
        if os.path.exists(guide_path):
            zf.write(guide_path, f"{APP_NAME} - Client Guide.html")
    buf.seek(0)
    return send_file(buf, mimetype="application/zip", as_attachment=True, download_name=f"{APP_SHORTNAME}-Setup.zip")


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
