#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sync Windows configuration files
.DESCRIPTION
    Copies PowerShell profile to pwsh directory, syncs Neovim configuration, and syncs AutoHotkey scripts.
    This script consolidates all configuration syncing functionality.
.EXAMPLE
    .\sync-config.ps1
#>

Write-Host "=== Windows Configuration Sync ===" -ForegroundColor Magenta
$ConfigRoot = $PSScriptRoot

# 1. Copy PowerShell profile to pwsh directory
Write-Host "`n--- Copying PowerShell Profile to pwsh directory ---" -ForegroundColor Yellow
$ProfileSource = "C:\Users\samue\OneDrive\Documents\PowerShell\Microsoft.PowerShell_profile.ps1"
$PwshDir = Join-Path $ConfigRoot "pwsh"
$ProfileTarget = Join-Path $PwshDir "Microsoft.PowerShell_profile.ps1"

# Ensure pwsh directory exists
if (!(Test-Path $PwshDir)) {
    New-Item -ItemType Directory -Path $PwshDir -Force | Out-Null
    Write-Host "Created pwsh directory" -ForegroundColor Green
}

Write-Host "Copying PowerShell profile from: $ProfileSource" -ForegroundColor Cyan
Write-Host "Copying to: $ProfileTarget" -ForegroundColor Cyan

if (Test-Path $ProfileSource) {
    try {
        Copy-Item $ProfileSource $ProfileTarget -Force
        Write-Host "PowerShell profile copied successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error copying PowerShell profile: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Warning: PowerShell profile not found at $ProfileSource" -ForegroundColor Red
}

# 2. Sync Neovim Configuration
Write-Host "`n--- Syncing Neovim Configuration ---" -ForegroundColor Yellow

# Source directory (your Neovim config)
$SourceDir = "$env:LOCALAPPDATA\nvim"

# Target directory
$TargetDir = Join-Path $ConfigRoot "nvim"
if (!(Test-Path $TargetDir)) {
    New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
}

Write-Host "Syncing Neovim config from: $SourceDir" -ForegroundColor Cyan
Write-Host "Syncing to: $TargetDir" -ForegroundColor Cyan

# Files and directories to copy
$ItemsToCopy = @(
    "init.lua",
    "lua"
)

# Copy each item
foreach ($Item in $ItemsToCopy) {
    $SourcePath = Join-Path $SourceDir $Item
    $TargetPath = Join-Path $TargetDir $Item

    if (Test-Path $SourcePath) {
        if (Test-Path $TargetPath) {
            Write-Host "Updating existing: $Item" -ForegroundColor Yellow
            Remove-Item $TargetPath -Recurse -Force
        }

        Write-Host "Copying: $Item" -ForegroundColor Green
        Copy-Item $SourcePath $TargetPath -Recurse -Force
    } else {
        Write-Host "Warning: $Item not found in source" -ForegroundColor Red
    }
}



# 3. Copy Windows Terminal settings
Write-Host "`n--- Copying Windows Terminal Settings ---" -ForegroundColor Yellow
$WinTermSource = "C:\Users\samue\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
$WinTermDir = Join-Path $ConfigRoot "winterm"
$WinTermTarget = Join-Path $WinTermDir "settings.json"

# Ensure winterm directory exists
if (!(Test-Path $WinTermDir)) {
    New-Item -ItemType Directory -Path $WinTermDir -Force | Out-Null
    Write-Host "Created winterm directory" -ForegroundColor Green
}

Write-Host "Copying Windows Terminal settings from: $WinTermSource" -ForegroundColor Cyan
Write-Host "Copying to: $WinTermTarget" -ForegroundColor Cyan

if (Test-Path $WinTermSource) {
    try {
        Copy-Item $WinTermSource $WinTermTarget -Force
        Write-Host "Windows Terminal settings copied successfully!" -ForegroundColor Green
    } catch {
        Write-Host "Error copying Windows Terminal settings: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "Warning: Windows Terminal settings not found at $WinTermSource" -ForegroundColor Red
}

# 4. Sync AutoHotkey scripts
Write-Host "`n--- Syncing AutoHotkey Scripts ---" -ForegroundColor Yellow
$AhkSourcePattern = @(
    "$env:USERPROFILE\*.ahk",
    "$env:USERPROFILE\Desktop\*.ahk"
)
$AhkTargetDir = Join-Path $ConfigRoot "ahk"

# Ensure ahk directory exists
if (!(Test-Path $AhkTargetDir)) {
    New-Item -ItemType Directory -Path $AhkTargetDir -Force | Out-Null
    Write-Host "Created ahk directory" -ForegroundColor Green
}

Write-Host "Syncing AutoHotkey scripts to: $AhkTargetDir" -ForegroundColor Cyan

$AhkFiles = @()
foreach ($Pattern in $AhkSourcePattern) {
    $Found = Get-ChildItem $Pattern -ErrorAction SilentlyContinue
    if ($Found) {
        $AhkFiles += $Found
    }
}

if ($AhkFiles.Count -gt 0) {
    foreach ($File in $AhkFiles) {
        $TargetPath = Join-Path $AhkTargetDir $File.Name
        Copy-Item $File.FullName $TargetPath -Force
        Write-Host "Synced: $($File.Name)" -ForegroundColor Green
    }
    Write-Host "AutoHotkey scripts synced successfully!" -ForegroundColor Green
} else {
    Write-Host "No AutoHotkey scripts found to sync" -ForegroundColor Yellow
}

Write-Host "`n=== Configuration Sync Complete ===" -ForegroundColor Magenta
Write-Host "All configs synced to: $ConfigRoot" -ForegroundColor Cyan
