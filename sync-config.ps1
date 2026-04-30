#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Sync Windows configuration files
.DESCRIPTION
    Copies PowerShell profile, Neovim config, Windows Terminal settings, and AutoHotkey
    scripts from their live system locations into this repo.

    By default shows an interactive menu to pick which sections to sync. Use -All to sync
    everything non-interactively, or pass any combination of -Profile, -Nvim, -WinTerm,
    -Ahk to sync specific sections.
.EXAMPLE
    .\sync-config.ps1
    .\sync-config.ps1 -All
    .\sync-config.ps1 -Nvim
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Profile,
    [switch]$Nvim,
    [switch]$WinTerm,
    [switch]$Ahk
)

Write-Host "=== Windows Configuration Sync ===" -ForegroundColor Magenta
$ConfigRoot = $PSScriptRoot

# Decide which sections to run
$AnySwitch = $All -or $Profile -or $Nvim -or $WinTerm -or $Ahk
if ($All) {
    $DoProfile = $true; $DoNvim = $true; $DoWinTerm = $true; $DoAhk = $true
} elseif ($AnySwitch) {
    $DoProfile = [bool]$Profile
    $DoNvim = [bool]$Nvim
    $DoWinTerm = [bool]$WinTerm
    $DoAhk = [bool]$Ahk
} else {
    Write-Host "`nSelect what to sync:" -ForegroundColor Yellow
    Write-Host "  1) PowerShell profile"
    Write-Host "  2) Neovim config"
    Write-Host "  3) Windows Terminal settings"
    Write-Host "  4) AutoHotkey scripts"
    Write-Host "  A) All"
    Write-Host "  Q) Quit"
    Write-Host "Enter selection (e.g. '1,3' or 'A'):" -ForegroundColor Cyan -NoNewline
    $Choice = (Read-Host).Trim().ToUpper()

    if ($Choice -eq 'Q' -or [string]::IsNullOrWhiteSpace($Choice)) {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    $DoProfile = $false; $DoNvim = $false; $DoWinTerm = $false; $DoAhk = $false
    if ($Choice -eq 'A') {
        $DoProfile = $true; $DoNvim = $true; $DoWinTerm = $true; $DoAhk = $true
    } else {
        $Parts = $Choice -split '[,\s]+' | Where-Object { $_ }
        foreach ($P in $Parts) {
            switch ($P) {
                '1' { $DoProfile = $true }
                '2' { $DoNvim = $true }
                '3' { $DoWinTerm = $true }
                '4' { $DoAhk = $true }
                default { Write-Host "Ignoring unknown selection: $P" -ForegroundColor Red }
            }
        }
    }

    if (-not ($DoProfile -or $DoNvim -or $DoWinTerm -or $DoAhk)) {
        Write-Host "Nothing selected. Cancelled." -ForegroundColor Yellow
        return
    }
}

# 1. Copy PowerShell profile to pwsh directory
if ($DoProfile) {
    Write-Host "`n--- Copying PowerShell Profile to pwsh directory ---" -ForegroundColor Yellow
    $ProfileSource = "$env:USERPROFILE\Documents_LOCAL\PowerShell\Microsoft.PowerShell_profile.ps1"
    $PwshDir = Join-Path $ConfigRoot "pwsh"
    $ProfileTarget = Join-Path $PwshDir "Microsoft.PowerShell_profile.ps1"

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
}

# 2. Sync Neovim Configuration
if ($DoNvim) {
    Write-Host "`n--- Syncing Neovim Configuration ---" -ForegroundColor Yellow
    $SourceDir = "$env:LOCALAPPDATA\nvim"
    $TargetDir = Join-Path $ConfigRoot "nvim"
    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    Write-Host "Syncing Neovim config from: $SourceDir" -ForegroundColor Cyan
    Write-Host "Syncing to: $TargetDir" -ForegroundColor Cyan

    $ItemsToCopy = @(
        "init.lua",
        "lua"
    )

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
}

# 3. Copy Windows Terminal settings
if ($DoWinTerm) {
    Write-Host "`n--- Copying Windows Terminal Settings ---" -ForegroundColor Yellow
    $WinTermSource = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $WinTermDir = Join-Path $ConfigRoot "winterm"
    $WinTermTarget = Join-Path $WinTermDir "settings.json"

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
}

# 4. Sync AutoHotkey scripts
if ($DoAhk) {
    Write-Host "`n--- Syncing AutoHotkey Scripts ---" -ForegroundColor Yellow
    $AhkSourcePattern = @(
        "$env:USERPROFILE\*.ahk",
        "$env:USERPROFILE\Desktop\*.ahk"
    )
    $AhkTargetDir = Join-Path $ConfigRoot "ahk"

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
}

Write-Host "`n=== Configuration Sync Complete ===" -ForegroundColor Magenta
Write-Host "Synced to: $ConfigRoot" -ForegroundColor Cyan
