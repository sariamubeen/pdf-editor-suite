@echo off
REM ============================================================================
REM  PDF Editor Suite — Windows Shell Wrapper
REM ============================================================================
REM  This batch file is the target of the .pdf file association.
REM  Windows calls this with the PDF path as %1 when a user double-clicks a PDF.
REM  It delegates to the PowerShell handler script.
REM ============================================================================

powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File "%~dp0Open-PDFInBrowser.ps1" "%~1"
