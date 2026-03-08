@echo off
setlocal

reg delete "HKCU\Software\Classes\SystemFileAssociations\.zip\shell\Unzipper" /f /reg:64 >nul 2>&1
if exist "%LOCALAPPDATA%\UnzipHere" rmdir /s /q "%LOCALAPPDATA%\UnzipHere"

echo Uninstalled.
pause
