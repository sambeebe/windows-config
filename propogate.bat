@echo off
setlocal enabledelayedexpansion

:: Set the base destination directory
set "CONFIG_DIR=%USERPROFILE%\windows-config"
set "STARTUP_DIR=%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"

:: Check if destination directories exist, create if not
if not exist "%CONFIG_DIR%" (
    mkdir "%CONFIG_DIR%"
    echo Created destination directory: %CONFIG_DIR%
)
echo.
echo Starting file copy operations...

:: Copy Neovim config to windows_config only
set "SRC=%LOCALAPPDATA%\nvim\init.lua"
if exist "!SRC!" (
    echo Copying: !SRC! to %CONFIG_DIR%
    copy /Y "!SRC!" "%CONFIG_DIR%"
) else (
    echo Warning: File not found - !SRC!
)

:: Copy AHK script to both locations
set "SRC=%USERPROFILE%\scripts\remapWin.ahk"
if exist "!SRC!" (
    echo Copying: !SRC! to %CONFIG_DIR%
    copy /Y "!SRC!" "%CONFIG_DIR%"
    
    echo Copying: !SRC! to %STARTUP_DIR%
    copy /Y "!SRC!" "%STARTUP_DIR%"
) else (
    echo Warning: File not found - !SRC!
)

set "PS_PROFILE=%USERPROFILE%\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
if exist "!PS_PROFILE!" (
    echo Copying PowerShell profile: !PS_PROFILE! to %CONFIG_DIR%
    copy /Y "!PS_PROFILE!" "%CONFIG_DIR%"
) else (
    echo Warning: PowerShell profile not found at !PS_PROFILE!
)
echo.

echo Copy operations completed!

:: Git operations - assumes you're already in the correct directory
echo.
echo Starting git operations...
cd /d "%CONFIG_DIR%"
git add .
git commit -m "update"
echo Git commit completed!

