@echo off
chcp 65001 >nul
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Setup-Veronica.ps1"
if errorlevel 1 (
  echo Falha na instalacao. Consulte README.md.
  pause
  exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Veronica-Local.ps1"
pause
