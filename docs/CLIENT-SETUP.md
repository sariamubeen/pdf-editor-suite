# Windows Client Setup Guide

## Installation

1. Get the `INSTALL.bat` file from your IT admin or download it
2. Double-click `INSTALL.bat`
3. If asked for admin permission, click Yes
4. When prompted for the server URL, press Enter to accept the default or type your server's address (e.g. `http://192.168.1.50:8080`)
5. Wait for "Setup Complete"
6. Done

---

## Opening a PDF

### If PDF Editor Suite is set as your default PDF app

Just double-click any PDF file. It will automatically upload to the server and open in the browser editor.

### If another app is still the default (e.g. Adobe, Edge)

1. Right-click the PDF file
2. Click **Open with**
3. Select **PDF Editor Suite (Browser)**
4. The PDF uploads automatically and opens in the browser editor

> **Tip:** If "PDF Editor Suite (Browser)" doesn't appear in the "Open with" list:
> 1. Click "Choose another app"
> 2. Scroll down and click "More apps"
> 3. Click "Look for another app on this PC"
> 4. Go to `C:\Program Files\PDFEditorSuite\`
> 5. Select `open-pdf.bat`

---

## What you can do in the editor

- View and read PDFs
- Edit text
- Fill in forms
- Add annotations and highlights
- Add comments
- Draw on the PDF
- Download the edited PDF
- Print

---

## Uninstall

Double-click `UNINSTALL.bat` or run:
```
C:\Program Files\PDFEditorSuite\Uninstall.bat
```

---

## Troubleshooting

**Browser opens but nothing loads**
- Check that the server is reachable: open `http://YOUR_SERVER:8080` in your browser
- If it doesn't load, the server may be down -- contact your IT admin

**PDF doesn't appear in the editor**
- Check the debug log: open File Explorer, type `%TEMP%` in the address bar, open `PDFEditorSuite-debug.log`

**"Enter a name for collaboration" popup**
- Type your name and click OK. This only appears once.
