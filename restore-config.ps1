#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restore Windows configuration files from this repo to their system locations
.DESCRIPTION
    Reverse of sync-config.ps1: copies PowerShell profile, Neovim config, Windows Terminal
    settings, and AutoHotkey scripts from this repo back out to their live system locations.

    By default shows an interactive menu to pick which sections to restore. Use -All to
    restore everything non-interactively, or pass any combination of -Profile, -Nvim,
    -WinTerm, -Ahk to restore specific sections.
.EXAMPLE
    .\restore-config.ps1
    .\restore-config.ps1 -All
    .\restore-config.ps1 -Profile -Ahk
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Profile,
    [switch]$Nvim,
    [switch]$WinTerm,
    [switch]$Ahk
)

Write-Host "=== Windows Configuration Restore ===" -ForegroundColor Magenta
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
    Write-Host "`nSelect what to restore:" -ForegroundColor Yellow
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

# 1. Restore PowerShell profile
if ($DoProfile) {
    Write-Host "`n--- Restoring PowerShell Profile ---" -ForegroundColor Yellow
    $ProfileSource = Join-Path $ConfigRoot "pwsh\Microsoft.PowerShell_profile.ps1"
    $ProfileTarget = "C:\Users\samue\Documents_LOCAL\PowerShell\Microsoft.PowerShell_profile.ps1"
    $ProfileTargetDir = Split-Path $ProfileTarget -Parent

    if (!(Test-Path $ProfileTargetDir)) {
        New-Item -ItemType Directory -Path $ProfileTargetDir -Force | Out-Null
        Write-Host "Created PowerShell profile directory" -ForegroundColor Green
    }

    Write-Host "Restoring PowerShell profile from: $ProfileSource" -ForegroundColor Cyan
    Write-Host "Restoring to: $ProfileTarget" -ForegroundColor Cyan

    if (Test-Path $ProfileSource) {
        try {
            Copy-Item $ProfileSource $ProfileTarget -Force
            Write-Host "PowerShell profile restored successfully!" -ForegroundColor Green
        } catch {
            Write-Host "Error restoring PowerShell profile: $($_.Exception.Message)" -ForegroundColor Red
        }
    } else {
        Write-Host "Warning: PowerShell profile not found at $ProfileSource" -ForegroundColor Red
    }
}

# 2. Restore Neovim Configuration
if ($DoNvim) {
    Write-Host "`n--- Restoring Neovim Configuration ---" -ForegroundColor Yellow
    $SourceDir = Join-Path $ConfigRoot "nvim"
    $TargetDir = "$env:LOCALAPPDATA\nvim"

    if (!(Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    Write-Host "Restoring Neovim config from: $SourceDir" -ForegroundColor Cyan
    Write-Host "Restoring to: $TargetDir" -ForegroundColor Cyan

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
            Write-Host "Warning: $Item not found in repo" -ForegroundColor Red
        }
    }
}

# 3. Restore Windows Terminal settings
if ($DoWinTerm) {
    Write-Host "`n--- Restoring Windows Terminal Settings ---" -ForegroundColor Yellow
    $WinTermSource = Join-Path $ConfigRoot "winterm\settings.json"
    $WinTermTarget = "C:\Users\samue\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
    $WinTermTargetDir = Split-Path $WinTermTarget -Parent

    Write-Host "Restoring Windows Terminal settings from: $WinTermSource" -ForegroundColor Cyan
    Write-Host "Restoring to: $WinTermTarget" -ForegroundColor Cyan

    if (Test-Path $WinTermSource) {
        if (!(Test-Path $WinTermTargetDir)) {
            Write-Host "Warning: Windows Terminal is not installed (target dir missing): $WinTermTargetDir" -ForegroundColor Red
        } else {
            try {
                Copy-Item $WinTermSource $WinTermTarget -Force
                Write-Host "Windows Terminal settings restored successfully!" -ForegroundColor Green
            } catch {
                Write-Host "Error restoring Windows Terminal settings: $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    } else {
        Write-Host "Warning: Windows Terminal settings not found at $WinTermSource" -ForegroundColor Red
    }
}

# 4. Restore AutoHotkey scripts
if ($DoAhk) {
    Write-Host "`n--- Restoring AutoHotkey Scripts ---" -ForegroundColor Yellow
    $AhkSourceDir = Join-Path $ConfigRoot "ahk"
    $AhkUserProfile = $env:USERPROFILE
    $AhkDesktop = Join-Path $env:USERPROFILE "Desktop"

    Write-Host "Restoring AutoHotkey scripts from: $AhkSourceDir" -ForegroundColor Cyan

    if (Test-Path $AhkSourceDir) {
        $AhkFiles = Get-ChildItem "$AhkSourceDir\*.ahk" -ErrorAction SilentlyContinue
        if ($AhkFiles.Count -gt 0) {
            foreach ($File in $AhkFiles) {
                # If file already exists on Desktop, update it there; otherwise place in USERPROFILE.
                $DesktopPath = Join-Path $AhkDesktop $File.Name
                $ProfilePath = Join-Path $AhkUserProfile $File.Name

                if (Test-Path $DesktopPath) {
                    Copy-Item $File.FullName $DesktopPath -Force
                    Write-Host "Restored to Desktop: $($File.Name)" -ForegroundColor Green
                } else {
                    Copy-Item $File.FullName $ProfilePath -Force
                    Write-Host "Restored to UserProfile: $($File.Name)" -ForegroundColor Green
                }
            }
            Write-Host "AutoHotkey scripts restored successfully!" -ForegroundColor Green
        } else {
            Write-Host "No AutoHotkey scripts found in repo" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: ahk directory not found at $AhkSourceDir" -ForegroundColor Red
    }
}

Write-Host "`n=== Configuration Restore Complete ===" -ForegroundColor Magenta
Write-Host "Restored from: $ConfigRoot" -ForegroundColor Cyan
