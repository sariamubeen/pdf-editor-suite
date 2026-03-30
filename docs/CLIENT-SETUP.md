# Windows Client Setup Guide

There are two ways to use PDF Editor Suite on Windows.

---

## Option A: One-Click Install (Recommended)

This makes PDF Editor Suite appear in your "Open with" menu for all PDF files.

### Steps

1. Get the `INSTALL.bat` file from your IT admin or download it
2. Double-click `INSTALL.bat`
3. If asked for admin permission, click Yes
4. When prompted for the server URL, press Enter to accept the default or type your server's address (e.g. `http://192.168.1.50:8080`)
5. Wait for "Setup Complete"
6. Done

### How to open a PDF after installation

1. Right-click any PDF file
2. Click "Open with"
3. Select "PDF Editor Suite (Browser)"
4. The PDF uploads automatically and opens in the browser editor

If "PDF Editor Suite (Browser)" doesn't appear in the list:
1. Click "Choose another app"
2. Scroll down and click "More apps"
3. Click "Look for another app on this PC"
4. Navigate to `C:\Program Files\PDFEditorSuite\`
5. Select `open-pdf.bat`

### To uninstall

Double-click `UNINSTALL.bat` or run the uninstaller at:
```
C:\Program Files\PDFEditorSuite\Uninstall.bat
```

---

## Option B: Use the Web Browser Directly

No installation needed. Works on any computer with a browser.

### Steps

1. Open your web browser (Edge, Chrome, Firefox)
2. Go to your server address, for example:
   ```
   http://172.20.4.58:8080
   ```
3. Click the upload area or drag a PDF file onto it
4. The PDF opens in the editor automatically

### Bookmark it

For quick access, bookmark the URL or pin the tab.

---

## What you can do in the editor

- View PDF documents
- Edit text in PDFs
- Fill in PDF forms
- Add annotations and highlights
- Add comments
- Draw on the PDF
- Download the edited PDF
- Print

---

## Troubleshooting

**"Open with" doesn't show PDF Editor Suite**
- Re-run INSTALL.bat
- Or use Option B (browser) instead

**Browser opens but nothing loads**
- Check that you can reach the server: open `http://YOUR_SERVER:8080` in your browser
- If it doesn't load, the server may be down -- contact your IT admin

**PDF doesn't open in the editor**
- Check the debug log at: `%TEMP%\PDFEditorSuite-debug.log`
  (Open File Explorer, type `%TEMP%` in the address bar, look for `PDFEditorSuite-debug.log`)
- The log shows exactly what happened when you tried to open the PDF

**"Enter a name for collaboration" popup**
- Just type your name and click OK. This only appears once.
