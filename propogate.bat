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
    copy "!SRC!" "%CONFIG_DIR%" /Y
) else (
    echo Warning: File not found - !SRC!
)
:: Copy AHK script to both locations
set "SRC=%USERPROFILE%\scripts\remapWin.ahk"
if exist "!SRC!" (
    echo Copying: !SRC! to %CONFIG_DIR%
    copy "!SRC!" "%CONFIG_DIR%" /Y
    
    echo Copying: !SRC! to %STARTUP_DIR%
    copy "!SRC!" "%CONFIG_DIR%" /Y
) else (
    echo Warning: File not found - !SRC!
)
echo.
echo Copy operations completed!

:: Git operations - assumes you're already in the correct directory
echo.
echo Starting git operations...
cd "%CONFIG_DIR%"
git add .
git commit -m "update"
echo Git commit completed!
