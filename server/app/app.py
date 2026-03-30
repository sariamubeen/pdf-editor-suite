"""
PDF Editor Suite - Web App
Bridges Windows clients with ONLYOFFICE Document Server.
Accepts PDF uploads, serves files, and renders the ONLYOFFICE editor.
"""

import os
import uuid
import json
import jwt
import time
from flask import Flask, request, jsonify, send_from_directory

app = Flask(__name__)

UPLOAD_DIR = os.environ.get("UPLOAD_DIR", "/app/uploads")
JWT_SECRET = os.environ.get("JWT_SECRET", "pdfeditorsuite")
ONLYOFFICE_URL = os.environ.get("ONLYOFFICE_URL", "http://localhost:8443")
APP_URL = os.environ.get("APP_URL", "http://localhost:8080")

os.makedirs(UPLOAD_DIR, exist_ok=True)


def make_token(payload):
    return jwt.encode(payload, JWT_SECRET, algorithm="HS256")


@app.route("/")
def index():
    return """<!DOCTYPE html>
<html>
<head><title>PDF Editor Suite</title>
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
<h1>PDF Editor Suite</h1>
<div class="upload" onclick="document.getElementById('f').click()">
  <p>Click or drag a PDF here to edit</p>
  <input type="file" id="f" accept=".pdf" onchange="upload(this.files[0])">
</div>
<p id="status" style="margin-top:16px"></p>
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

    # Unique filename to avoid collisions
    safe_name = f"{uuid.uuid4().hex[:8]}_{f.filename}"
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
        "editorConfig": {
            "callbackUrl": callback_url,
            "mode": "edit",
            "lang": "en",
            "customization": {
                "autosave": True,
                "forcesave": True,
                "compactHeader": True,
            },
        },
    }

    token = make_token(config)
    config["token"] = token

    title = config["document"]["title"]
    config_json = json.dumps(config)

    return f"""<!DOCTYPE html>
<html>
<head>
<title>{title} - PDF Editor Suite</title>
<style>
body {{ margin: 0; overflow: hidden; }}
#editor {{ width: 100vw; height: 100vh; }}
</style>
</head>
<body>
<div id="editor"></div>
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

    # Status 2 = document ready for saving
    # Status 6 = document being edited (force save)
    if status in (2, 6):
        download_url = data.get("url")
        key = data.get("key", "")
        if download_url:
            # Download the edited file and overwrite the original
            import urllib.request
            # Find the original filename from the key or use as-is
            for fname in os.listdir(UPLOAD_DIR):
                if key in fname or True:  # Save to same directory
                    pass
            try:
                urllib.request.urlretrieve(download_url, os.path.join(UPLOAD_DIR, f"saved_{key}.pdf"))
            except Exception:
                pass

    return jsonify(error=0)


@app.route("/health")
def health():
    return jsonify(status="ok")


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080, debug=False)
