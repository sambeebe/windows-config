@echo off
setlocal
set "SCRIPT_DIR=%~dp0"

where pwsh.exe >nul 2>nul
if %errorlevel% equ 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%launch-ahks.ps1" %*
) else (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%launch-ahks.ps1" %*
)
