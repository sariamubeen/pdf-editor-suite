# SIERA PDF

**Windows PDF handler that uploads to MinIO and opens the file in ShareSuite for editing.**

---

## How it works

```
User double-clicks a PDF (or right-click > Open with > SIERA PDF)
            |
            v
  Handler uploads PDF to MinIO bucket "pdfplugin"
            |
            v
  Browser opens ShareSuite with the MinIO URL as ?pdfUrl=...
            |
            v
  User edits the PDF in ShareSuite
```

Configuration is baked into the installer:

| Thing | Value |
|-------|-------|
| MinIO API | `http://172.20.5.65:9000` |
| Bucket | `pdfplugin` (public write required) |
| ShareSuite URL | `https://sharesuite.mup-digital.com/#m=core:a=pdf-generation-frontend:view=pdf-generation-frontend:ctxId=2835:pdfUrl=...` |
| Install dir | `C:\Program Files\SieraPDF` |
| ProgId | `SieraPDF.PDF` |

---

## Install

1. Download `INSTALL.bat` to the Windows machine
2. Double-click it
3. Click **Yes** at the admin prompt
4. Done — SIERA PDF is now registered as a PDF handler with the SIERA icon

## Uninstall

Run `UNINSTALL.bat` or `C:\Program Files\SieraPDF\Uninstall.bat`.

---

## Opening a PDF

- **Default handler**: Double-click any `.pdf`
- **Open with menu**: Right-click PDF > Open with > SIERA PDF
- **Set as default**: Settings > Apps > Default apps > `.pdf` > choose SIERA PDF

---

## MinIO requirements

The `pdfplugin` bucket must allow **anonymous PUT** so the Windows handler can upload without credentials. Set this bucket policy in the MinIO console:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {"AWS": ["*"]},
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": ["arn:aws:s3:::pdfplugin/*"]
    }
  ]
}
```

---

## Debugging

Check the log file at `%TEMP%\SieraPDF-debug.log` — it shows the upload URL, response, and any errors.

Open File Explorer, paste `%TEMP%` in the address bar, look for `SieraPDF-debug.log`.

---

## License

MIT — see [LICENSE](LICENSE).
