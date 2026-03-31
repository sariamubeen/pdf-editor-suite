"""
SIERA PDF - Web App
Bridges Windows clients with ONLYOFFICE Document Server.
Accepts PDF uploads, serves files, and renders the ONLYOFFICE editor.
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
from werkzeug.utils import secure_filename
from flask import Flask, request, jsonify, send_from_directory, send_file

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


@app.route("/logo.png")
def logo():
    return send_from_directory(os.path.join(os.path.dirname(__file__), "bundle"), "siera-logo.png")


@app.route("/")
def index():
    return """<!DOCTYPE html>
<html>
<head><title>SIERA PDF</title>
<style>
body { font-family: sans-serif; display: flex; justify-content: center; align-items: center;
       height: 100vh; margin: 0; background: #f5f5f5; }
.box { text-align: center; padding: 40px; background: white; border-radius: 12px;
       box-shadow: 0 2px 12px rgba(0,0,0,0.1); }
h1 { margin: 0 0 8px; }
p { color: #666; margin: 0 0 24px; }
.upload { border: 2px dashed #ccc; padding: 40px; border-radius: 8px; cursor: pointer; }
.upload:hover { border-color: #4a90d9; background: #f0f6ff; }
input[type=file] { display: none; }
</style></head>
<body>
<div class="box">
<img src="/logo.png" alt="SIERA PDF" style="height:60px;margin-bottom:12px">
<h1>SIERA PDF</h1>
<div class="upload" onclick="document.getElementById('f').click()">
  <p>Click or drag a PDF here to edit</p>
  <input type="file" id="f" accept=".pdf" onchange="upload(this.files[0])">
</div>
<p id="status" style="margin-top:16px"></p>
<p style="margin-top:24px;font-size:13px">
  <a href="/signature" style="color:#2563eb">Manage My Signature</a>
  &nbsp;|&nbsp;
  <a href="/sign" style="color:#2563eb">Sign a PDF</a>
  &nbsp;|&nbsp;
  <a href="/download" style="color:#2563eb">Download Installer</a>
</p>
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


@app.route("/api/upload", methods=["POST"])
def upload():
    if "file" not in request.files:
        return jsonify(error="No file provided"), 400

    f = request.files["file"]
    if not f.filename.lower().endswith(".pdf"):
        return jsonify(error="Only PDF files are supported"), 400

    # Unique filename to avoid collisions and path traversal
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
            "permissions": {
                "edit": True,
                "download": True,
                "print": True,
                "fillForms": True,
                "comment": True,
            },
        },
        "documentType": "pdf",
        "height": "100%",
        "width": "100%",
        "editorConfig": {
            "callbackUrl": callback_url,
            "mode": "edit",
            "lang": "en",
            "user": {
                "id": "user1",
                "name": "User",
            },
            "customization": {
                "autosave": True,
                "forcesave": True,
                "compactHeader": False,
            },
        },
    }

    token = make_token(config)
    config["token"] = token

    title = config["document"]["title"]
    config_json = json.dumps(config)

    return f"""<!DOCTYPE html>
<html style="height:100%;margin:0;padding:0;overflow:hidden">
<head>
<title>{title} - SIERA PDF</title>
</head>
<body style="height:100%;margin:0;padding:0;overflow:hidden">
<div id="editor" style="position:absolute;top:0;left:0;right:0;bottom:0"></div>
<script src="{ONLYOFFICE_URL}/web-apps/apps/api/documents/api.js"></script>
<script>
new DocsAPI.DocEditor("editor", {config_json});
</script>
</body>
</html>"""


@app.route("/api/callback", methods=["POST"])
def callback():
    """Handle ONLYOFFICE save/close notifications."""
    data = request.json or {}
    status = data.get("status", 0)

    # Status 2 = document ready for saving, 6 = force save
    if status in (2, 6):
        download_url = data.get("url")
        key = data.get("key", "")
        if download_url:
            # Find the original file by matching the key in filenames
            target = None
            for fname in os.listdir(UPLOAD_DIR):
                if fname.endswith(".pdf") and not fname.startswith("sign_input_"):
                    target = os.path.join(UPLOAD_DIR, fname)
                    break
            if not target:
                target = os.path.join(UPLOAD_DIR, f"saved_{key}.pdf")

            try:
                urllib.request.urlretrieve(download_url, target)
                logging.info(f"Callback: saved edited PDF to {target}")
            except Exception as e:
                logging.error(f"Callback: failed to save PDF: {e}")

    return jsonify(error=0)


@app.route("/signature")
def signature_page():
    """Draw and save your signature."""
    # Check if a signature already exists
    existing = None
    sigs = [f for f in os.listdir(SIGNATURE_DIR) if f.endswith(".png")]
    if sigs:
        existing = f"{APP_URL}/signatures/{sigs[0]}"

    return f"""<!DOCTYPE html>
<html>
<head><title>My Signature - SIERA PDF</title>
<style>
body {{ font-family: sans-serif; margin: 0; background: #f5f5f5; display: flex; justify-content: center; padding: 40px; }}
.container {{ background: white; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.1); padding: 32px; max-width: 600px; width: 100%; }}
h1 {{ font-size: 20px; margin: 0 0 4px; }}
.sub {{ color: #666; font-size: 13px; margin-bottom: 24px; }}
canvas {{ border: 2px solid #e0e0e0; border-radius: 8px; cursor: crosshair; display: block; background: white; }}
.buttons {{ margin-top: 16px; display: flex; gap: 10px; }}
.btn {{ padding: 10px 24px; border: none; border-radius: 6px; font-size: 14px; cursor: pointer; }}
.btn-primary {{ background: #2563eb; color: white; }}
.btn-primary:hover {{ background: #1d4ed8; }}
.btn-secondary {{ background: #e5e7eb; color: #333; }}
.btn-secondary:hover {{ background: #d1d5db; }}
.btn-danger {{ background: #ef4444; color: white; }}
.btn-danger:hover {{ background: #dc2626; }}
.existing {{ margin-top: 20px; padding: 16px; background: #f0fdf4; border: 1px solid #bbf7d0; border-radius: 8px; }}
.existing img {{ max-width: 300px; border: 1px solid #e0e0e0; border-radius: 4px; background: white; }}
#status {{ margin-top: 12px; font-size: 13px; color: #16a34a; }}
a {{ color: #2563eb; text-decoration: none; }}
</style></head>
<body>
<div class="container">
<h1>My Signature</h1>
<p class="sub">Draw your signature below. It will be saved and reused when you sign PDFs.</p>

{'<div class="existing"><p><strong>Current signature:</strong></p><img src="' + existing + '"><br><br><a href="/signature/delete" class="btn btn-danger" style="color:white;padding:6px 16px;text-decoration:none;border-radius:4px;font-size:13px">Delete and redraw</a></div>' if existing else ''}

<canvas id="pad" width="560" height="200"></canvas>
<div class="buttons">
  <button class="btn btn-primary" onclick="save()">Save Signature</button>
  <button class="btn btn-secondary" onclick="clear()">Clear</button>
  <a href="/" class="btn btn-secondary" style="text-decoration:none;display:inline-block">Back</a>
</div>
<div id="status"></div>
</div>

<script>
var canvas = document.getElementById('pad');
var ctx = canvas.getContext('2d');
var drawing = false;

ctx.strokeStyle = '#000';
ctx.lineWidth = 2.5;
ctx.lineCap = 'round';
ctx.lineJoin = 'round';

canvas.addEventListener('mousedown', function(e) {{
  drawing = true;
  ctx.beginPath();
  ctx.moveTo(e.offsetX, e.offsetY);
}});
canvas.addEventListener('mousemove', function(e) {{
  if (!drawing) return;
  ctx.lineTo(e.offsetX, e.offsetY);
  ctx.stroke();
}});
canvas.addEventListener('mouseup', function() {{ drawing = false; }});
canvas.addEventListener('mouseleave', function() {{ drawing = false; }});

// Touch support
canvas.addEventListener('touchstart', function(e) {{
  e.preventDefault();
  var r = canvas.getBoundingClientRect();
  var t = e.touches[0];
  drawing = true;
  ctx.beginPath();
  ctx.moveTo(t.clientX - r.left, t.clientY - r.top);
}});
canvas.addEventListener('touchmove', function(e) {{
  e.preventDefault();
  if (!drawing) return;
  var r = canvas.getBoundingClientRect();
  var t = e.touches[0];
  ctx.lineTo(t.clientX - r.left, t.clientY - r.top);
  ctx.stroke();
}});
canvas.addEventListener('touchend', function() {{ drawing = false; }});

function clear() {{
  ctx.clearRect(0, 0, canvas.width, canvas.height);
  document.getElementById('status').textContent = '';
}}

function save() {{
  var data = canvas.toDataURL('image/png');
  fetch('/api/signature', {{
    method: 'POST',
    headers: {{'Content-Type': 'application/json'}},
    body: JSON.stringify({{image: data}})
  }})
  .then(function(r) {{ return r.json(); }})
  .then(function(d) {{
    if (d.ok) {{
      document.getElementById('status').textContent = 'Signature saved!';
      setTimeout(function() {{ location.reload(); }}, 1000);
    }} else {{
      document.getElementById('status').textContent = 'Error: ' + (d.error || 'Unknown');
    }}
  }});
}}
</script>
</body></html>"""


@app.route("/api/signature", methods=["POST"])
def save_signature():
    """Save drawn signature as PNG."""
    data = request.json or {}
    image_data = data.get("image", "")
    if not image_data.startswith("data:image/png;base64,"):
        return jsonify(ok=False, error="Invalid image data"), 400

    b64 = image_data.split(",", 1)[1]
    img_bytes = base64.b64decode(b64)

    # Remove old signatures (only .png files)
    for fname in os.listdir(SIGNATURE_DIR):
        if fname.endswith(".png"):
            os.remove(os.path.join(SIGNATURE_DIR, fname))

    sig_file = f"signature_{uuid.uuid4().hex[:8]}.png"
    with open(os.path.join(SIGNATURE_DIR, sig_file), "wb") as f:
        f.write(img_bytes)

    return jsonify(ok=True, filename=sig_file)


@app.route("/signatures/<filename>")
def serve_signature(filename):
    return send_from_directory(SIGNATURE_DIR, filename)


@app.route("/signature/delete", methods=["GET", "POST"])
def delete_signature():
    for fname in os.listdir(SIGNATURE_DIR):
        if fname.endswith(".png"):
            os.remove(os.path.join(SIGNATURE_DIR, fname))
    return """<script>window.location='/signature';</script>"""


@app.route("/sign")
def sign_page():
    """Upload a PDF to stamp your signature on it."""
    # Check if signature exists
    sigs = [f for f in os.listdir(SIGNATURE_DIR) if f.endswith(".png")]
    if not sigs:
        return """<!DOCTYPE html><html><head><title>Sign PDF</title>
<style>body{font-family:sans-serif;display:flex;justify-content:center;padding:60px;background:#f5f5f5}
.box{background:white;padding:32px;border-radius:12px;box-shadow:0 2px 12px rgba(0,0,0,0.1);text-align:center;max-width:400px}
a{color:#2563eb}</style></head><body>
<div class="box"><h2>No signature found</h2><p>You need to draw your signature first.</p>
<p><a href="/signature">Draw My Signature</a></p></div></body></html>"""

    return """<!DOCTYPE html>
<html>
<head><title>Sign a PDF - SIERA PDF</title>
<style>
body { font-family: sans-serif; margin: 0; background: #f5f5f5; display: flex; justify-content: center; padding: 40px; }
.container { background: white; border-radius: 12px; box-shadow: 0 2px 12px rgba(0,0,0,0.1); padding: 32px; max-width: 500px; width: 100%; }
h1 { font-size: 20px; margin: 0 0 4px; }
.sub { color: #666; font-size: 13px; margin-bottom: 24px; }
.upload { border: 2px dashed #ccc; padding: 30px; border-radius: 8px; cursor: pointer; text-align: center; }
.upload:hover { border-color: #2563eb; background: #f0f6ff; }
input[type=file] { display: none; }
label { display: block; margin: 16px 0 6px; font-weight: 600; font-size: 14px; }
select, input[type=number] { width: 100%; padding: 8px; border: 1px solid #d1d5db; border-radius: 6px; font-size: 14px; box-sizing: border-box; }
.btn { padding: 10px 24px; border: none; border-radius: 6px; font-size: 14px; cursor: pointer; background: #2563eb; color: white; width: 100%; margin-top: 20px; }
.btn:hover { background: #1d4ed8; }
.btn:disabled { background: #93c5fd; cursor: not-allowed; }
#status { margin-top: 12px; font-size: 13px; text-align: center; }
a { color: #2563eb; text-decoration: none; }
</style></head>
<body>
<div class="container">
<h1>Sign a PDF</h1>
<p class="sub">Upload a PDF and your saved signature will be stamped on it.</p>

<div class="upload" onclick="document.getElementById('f').click()">
  <p>Click to select a PDF</p>
  <input type="file" id="f" accept=".pdf" onchange="fileSelected(this)">
</div>
<p id="fname" style="font-size:13px;color:#666;margin-top:8px"></p>

<label>Signature position</label>
<select id="position">
  <option value="bottom-right">Bottom Right</option>
  <option value="bottom-left">Bottom Left</option>
  <option value="bottom-center">Bottom Center</option>
  <option value="top-right">Top Right</option>
  <option value="top-left">Top Left</option>
  <option value="top-center">Top Center</option>
</select>

<label>Page</label>
<select id="page">
  <option value="last">Last page</option>
  <option value="first">First page</option>
  <option value="all">All pages</option>
</select>

<button class="btn" id="signBtn" onclick="signPdf()" disabled>Sign PDF</button>
<div id="status"></div>

<p style="margin-top:20px;font-size:13px;text-align:center">
  <a href="/signature">Change my signature</a> | <a href="/">Back to home</a>
</p>
</div>

<script>
var selectedFile = null;
function fileSelected(input) {
  selectedFile = input.files[0];
  document.getElementById('fname').textContent = selectedFile ? selectedFile.name : '';
  document.getElementById('signBtn').disabled = !selectedFile;
}

function signPdf() {
  if (!selectedFile) return;
  var btn = document.getElementById('signBtn');
  btn.disabled = true;
  btn.textContent = 'Signing...';
  document.getElementById('status').textContent = '';

  var fd = new FormData();
  fd.append('file', selectedFile);
  fd.append('position', document.getElementById('position').value);
  fd.append('page', document.getElementById('page').value);

  fetch('/api/sign', {method:'POST', body:fd})
  .then(function(r) {
    if (!r.ok) throw new Error('Server error');
    return r.blob();
  })
  .then(function(blob) {
    var url = URL.createObjectURL(blob);
    var a = document.createElement('a');
    a.href = url;
    a.download = 'signed_' + selectedFile.name;
    a.click();
    document.getElementById('status').innerHTML = '<span style="color:#16a34a">Signed! Download started.</span>';
    btn.disabled = false;
    btn.textContent = 'Sign PDF';
  })
  .catch(function(e) {
    document.getElementById('status').innerHTML = '<span style="color:#ef4444">Error: ' + e.message + '</span>';
    btn.disabled = false;
    btn.textContent = 'Sign PDF';
  });
}
</script>
</body></html>"""


@app.route("/api/sign", methods=["POST"])
def sign_pdf():
    """Stamp saved signature onto uploaded PDF."""
    from pypdf import PdfReader, PdfWriter
    from reportlab.pdfgen import canvas as rl_canvas
    from reportlab.lib.utils import ImageReader
    from PIL import Image

    if "file" not in request.files:
        return jsonify(error="No file"), 400

    pdf_file = request.files["file"]
    if not pdf_file.filename.lower().endswith(".pdf"):
        return jsonify(error="Only PDF files supported"), 400

    # Find saved signature
    sigs = [f for f in os.listdir(SIGNATURE_DIR) if f.endswith(".png")]
    if not sigs:
        return jsonify(error="No signature saved"), 400

    sig_path = os.path.join(SIGNATURE_DIR, sigs[0])
    position = request.form.get("position", "bottom-right")
    page_choice = request.form.get("page", "last")

    # Save uploaded PDF to temp
    tmp_pdf = os.path.join(UPLOAD_DIR, f"sign_input_{uuid.uuid4().hex[:8]}.pdf")
    pdf_file.save(tmp_pdf)

    try:
        reader = PdfReader(tmp_pdf)
        writer = PdfWriter()

        # Load signature image and get dimensions
        sig_img = Image.open(sig_path)
        # Scale signature: max 150px wide, keep aspect ratio
        sig_w = 150
        sig_h = int(sig_img.height * (sig_w / sig_img.width))

        # Determine which pages to sign
        total_pages = len(reader.pages)
        if page_choice == "first":
            sign_pages = {0}
        elif page_choice == "all":
            sign_pages = set(range(total_pages))
        else:  # last
            sign_pages = {total_pages - 1}

        for i, page in enumerate(reader.pages):
            if i in sign_pages:
                # Create overlay with signature
                page_w = float(page.mediabox.width)
                page_h = float(page.mediabox.height)

                # Calculate position
                margin = 40
                if "right" in position:
                    x = page_w - sig_w - margin
                elif "left" in position:
                    x = margin
                else:  # center
                    x = (page_w - sig_w) / 2

                if "top" in position:
                    y = page_h - sig_h - margin
                else:  # bottom
                    y = margin

                # Create overlay PDF with signature
                overlay_buf = io.BytesIO()
                c = rl_canvas.Canvas(overlay_buf, pagesize=(page_w, page_h))
                c.drawImage(ImageReader(sig_path), x, y, sig_w, sig_h, mask="auto")
                c.save()
                overlay_buf.seek(0)

                overlay_page = PdfReader(overlay_buf).pages[0]
                page.merge_page(overlay_page)

            writer.add_page(page)

        # Write signed PDF to buffer
        output_buf = io.BytesIO()
        writer.write(output_buf)
        output_buf.seek(0)

        return send_file(output_buf, mimetype="application/pdf", as_attachment=True, download_name=f"signed_{pdf_file.filename}")

    finally:
        # Cleanup temp file
        if os.path.exists(tmp_pdf):
            os.remove(tmp_pdf)


@app.route("/download")
def download():
    """Serve a zip containing INSTALL.bat + Client Guide for Windows users."""
    buf = io.BytesIO()
    with zipfile.ZipFile(buf, "w", zipfile.ZIP_DEFLATED) as zf:
        # Add INSTALL.bat from the bundled copy
        install_path = os.path.join(os.path.dirname(__file__), "bundle", "INSTALL.bat")
        if os.path.exists(install_path):
            zf.write(install_path, "INSTALL.bat")

        # Add client guide
        guide_path = os.path.join(os.path.dirname(__file__), "bundle", "PDF-Editor-Suite-Client-Guide.html")
        if os.path.exists(guide_path):
            zf.write(guide_path, "PDF-Editor-Suite-Client-Guide.html")

        # Add UNINSTALL.bat
        uninstall_path = os.path.join(os.path.dirname(__file__), "bundle", "UNINSTALL.bat")
        if os.path.exists(uninstall_path):
            zf.write(uninstall_path, "UNINSTALL.bat")

    buf.seek(0)
    return send_file(buf, mimetype="application/zip", as_attachment=True, download_name="SIERA-PDF-Setup.zip")


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
