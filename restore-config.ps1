#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restore Windows configuration files from this repo to their system locations
.DESCRIPTION
    Reverse of sync-config.ps1: copies PowerShell profile, Neovim config, Windows Terminal
    settings, and AutoHotkey scripts from this repo back out to their live system locations.

    By default shows an interactive menu to pick which sections to restore. Use -All to
    restore everything non-interactively, or pass any combination of -Profile, -Nvim,
    -WinTerm, -Ahk, -Mpv, -PowerToys, -Installs to restore specific sections.
.EXAMPLE
    .\restore-config.ps1
    .\restore-config.ps1 -All
    .\restore-config.ps1 -Profile -Ahk
    .\restore-config.ps1 -Installs
#>
[CmdletBinding()]
param(
    [switch]$All,
    [switch]$Profile,
    [switch]$Nvim,
    [switch]$WinTerm,
    [switch]$Ahk,
    [switch]$Mpv,
    [switch]$PowerToys,
    [switch]$Installs,
    [switch]$Fonts
)

Write-Host "=== Windows Configuration Restore ===" -ForegroundColor Magenta
$ConfigRoot = $PSScriptRoot

function Install-WingetPackageIfMissing {
    param(
        [Parameter(Mandatory=$true)][string[]]$CommandNames,
        [Parameter(Mandatory=$true)][string]$PackageId,
        [Parameter(Mandatory=$true)][string]$DisplayName
    )

    $IsInstalled = $false
    foreach ($CommandName in $CommandNames) {
        if (Get-Command $CommandName -ErrorAction SilentlyContinue) {
            $IsInstalled = $true
            break
        }
    }

    if ($IsInstalled) {
        Write-Host "$DisplayName is already installed." -ForegroundColor Green
        return
    }

    $Winget = Get-Command winget.exe -ErrorAction SilentlyContinue
    if (-not $Winget) {
        Write-Host "winget is not available, so $DisplayName could not be installed automatically." -ForegroundColor Red
        return
    }

    Write-Host "Installing $DisplayName..." -ForegroundColor Cyan
    try {
        & $Winget.Source install --id $PackageId --exact --accept-package-agreements --accept-source-agreements
        if ($LASTEXITCODE -eq 0) {
            Write-Host "$DisplayName installed successfully." -ForegroundColor Green
        } else {
            Write-Host "Failed to install $DisplayName (exit code $LASTEXITCODE)." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error installing ${DisplayName}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Decide which sections to run
$AnySwitch = $All -or $Profile -or $Nvim -or $WinTerm -or $Ahk -or $Mpv -or $PowerToys -or $Installs -or $Fonts
if ($All) {
    $DoProfile = $true; $DoNvim = $true; $DoWinTerm = $true; $DoAhk = $true; $DoMpv = $true; $DoPowerToys = $true; $DoInstalls = $true; $DoFonts = $true
} elseif ($AnySwitch) {
    $DoProfile = [bool]$Profile
    $DoNvim = [bool]$Nvim
    $DoWinTerm = [bool]$WinTerm
    $DoAhk = [bool]$Ahk
    $DoMpv = [bool]$Mpv
    $DoPowerToys = [bool]$PowerToys
    $DoInstalls = [bool]$Installs
    $DoFonts = [bool]$Fonts
} else {
    Write-Host "`nSelect what to restore:" -ForegroundColor Yellow
    Write-Host "  1) PowerShell profile"
    Write-Host "  2) Neovim config"
    Write-Host "  3) Windows Terminal settings"
    Write-Host "  4) AutoHotkey scripts"
    Write-Host "  5) mpv config"
    Write-Host "  6) PowerToys settings"
    Write-Host "  7) Installs (AutoHotkey, tre-command, PowerToys)"
    Write-Host "  8) Fonts (CaskaydiaMono Nerd Font)"
    Write-Host "  A) All"
    Write-Host "  Q) Quit"
    Write-Host "Enter selection (e.g. '1,3' or 'A'):" -ForegroundColor Cyan -NoNewline
    $Choice = (Read-Host).Trim().ToUpper()

    if ($Choice -eq 'Q' -or [string]::IsNullOrWhiteSpace($Choice)) {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    $DoProfile = $false; $DoNvim = $false; $DoWinTerm = $false; $DoAhk = $false; $DoMpv = $false; $DoPowerToys = $false; $DoInstalls = $false; $DoFonts = $false
    if ($Choice -eq 'A') {
        $DoProfile = $true; $DoNvim = $true; $DoWinTerm = $true; $DoAhk = $true; $DoMpv = $true; $DoPowerToys = $true; $DoInstalls = $true; $DoFonts = $true
    } else {
        $Parts = $Choice -split '[,\s]+' | Where-Object { $_ }
        foreach ($P in $Parts) {
            switch ($P) {
                '1' { $DoProfile = $true }
                '2' { $DoNvim = $true }
                '3' { $DoWinTerm = $true }
                '4' { $DoAhk = $true }
                '5' { $DoMpv = $true }
                '6' { $DoPowerToys = $true }
                '7' { $DoInstalls = $true }
                '8' { $DoFonts = $true }
                default { Write-Host "Ignoring unknown selection: $P" -ForegroundColor Red }
            }
        }
    }

    if (-not ($DoProfile -or $DoNvim -or $DoWinTerm -or $DoAhk -or $DoMpv -or $DoPowerToys -or $DoInstalls -or $DoFonts)) {
        Write-Host "Nothing selected. Cancelled." -ForegroundColor Yellow
        return
    }
}

# 1. Restore PowerShell profile
if ($DoProfile) {
    Write-Host "`n--- Restoring PowerShell Profile ---" -ForegroundColor Yellow
    $ProfileSource = Join-Path $ConfigRoot "pwsh\Microsoft.PowerShell_profile.ps1"
    $ProfileTarget = "$env:USERPROFILE\Documents_LOCAL\PowerShell\Microsoft.PowerShell_profile.ps1"
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
    $WinTermTarget = "$env:LOCALAPPDATA\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
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
    $AhkStartupDir = [Environment]::GetFolderPath('Startup')

    Write-Host "Restoring AutoHotkey scripts from: $AhkSourceDir" -ForegroundColor Cyan

    $AhkInstalled = $null -ne (Get-Command AutoHotkey.exe -ErrorAction SilentlyContinue) -or
        $null -ne (Get-Command AutoHotkey64.exe -ErrorAction SilentlyContinue)

    if (-not $AhkInstalled) {
        Write-Host "AutoHotkey is not installed. Run restore-config.ps1 -Installs to install it." -ForegroundColor Yellow
    }

    if (Test-Path $AhkSourceDir) {
        $AhkFiles = Get-ChildItem "$AhkSourceDir\*.ahk" -ErrorAction SilentlyContinue
        if ($AhkFiles.Count -gt 0) {
            if (!(Test-Path $AhkStartupDir)) {
                New-Item -ItemType Directory -Path $AhkStartupDir -Force | Out-Null
            }

            foreach ($File in $AhkFiles) {
                $StartupPath = Join-Path $AhkStartupDir $File.Name
                Copy-Item $File.FullName $StartupPath -Force
                Write-Host "Restored to Startup: $($File.Name)" -ForegroundColor Green
            }
            Write-Host "AutoHotkey scripts restored successfully to: $AhkStartupDir" -ForegroundColor Green
        } else {
            Write-Host "No AutoHotkey scripts found in repo" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: ahk directory not found at $AhkSourceDir" -ForegroundColor Red
    }
}

# 5. Restore mpv config
if ($DoMpv) {
    Write-Host "`n--- Restoring mpv Config ---" -ForegroundColor Yellow
    $MpvSourceDir = Join-Path $ConfigRoot "mpv"
    $MpvTargetDir = "$env:APPDATA\mpv"

    if (!(Test-Path $MpvTargetDir)) {
        New-Item -ItemType Directory -Path $MpvTargetDir -Force | Out-Null
    }

    Write-Host "Restoring mpv config from: $MpvSourceDir" -ForegroundColor Cyan
    Write-Host "Restoring to: $MpvTargetDir" -ForegroundColor Cyan

    $ItemsToCopy = @(
        "mpv.conf",
        "scripts"
    )

    foreach ($Item in $ItemsToCopy) {
        $SourcePath = Join-Path $MpvSourceDir $Item
        $TargetPath = Join-Path $MpvTargetDir $Item

        if (Test-Path $SourcePath) {
            if (Test-Path $TargetPath) {
                Write-Host "Updating existing: $Item" -ForegroundColor Yellow
                Remove-Item $TargetPath -Recurse -Force
            }

            Write-Host "Copying: $Item" -ForegroundColor Green
            Copy-Item $SourcePath $TargetPath -Recurse -Force
        } else {
            Write-Host "Warning: $Item not found in repo" -ForegroundColor Yellow
        }
    }
}

# 6. Restore PowerToys settings
if ($DoPowerToys) {
    Write-Host "`n--- Restoring PowerToys Settings ---" -ForegroundColor Yellow
    $PowerToysSourceDir = Join-Path $ConfigRoot "powertoys"
    $PowerToysTargetDir = "$env:LOCALAPPDATA\Microsoft\PowerToys"

    if (!(Test-Path $PowerToysTargetDir)) {
        New-Item -ItemType Directory -Path $PowerToysTargetDir -Force | Out-Null
    }

    Write-Host "Restoring PowerToys settings from: $PowerToysSourceDir" -ForegroundColor Cyan
    Write-Host "Restoring to: $PowerToysTargetDir" -ForegroundColor Cyan

    if (Test-Path $PowerToysSourceDir) {
        $SettingsFiles = Get-ChildItem -LiteralPath $PowerToysSourceDir -Recurse -Filter settings.json -File -ErrorAction SilentlyContinue
        if ($SettingsFiles) {
            foreach ($File in $SettingsFiles) {
                $RelativePath = $File.FullName.Substring($PowerToysSourceDir.Length).TrimStart('\')
                $TargetPath = Join-Path $PowerToysTargetDir $RelativePath
                $TargetParent = Split-Path $TargetPath -Parent

                if (!(Test-Path $TargetParent)) {
                    New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null
                }

                Copy-Item $File.FullName $TargetPath -Force
                Write-Host "Restored: $RelativePath" -ForegroundColor Green
            }
            Write-Host "PowerToys settings restored successfully!" -ForegroundColor Green
        } else {
            Write-Host "Warning: No PowerToys settings.json files found in repo at $PowerToysSourceDir" -ForegroundColor Yellow
        }
    } else {
        Write-Host "Warning: PowerToys settings not found in repo at $PowerToysSourceDir" -ForegroundColor Yellow
    }
}

# 7. Install packages
if ($DoInstalls) {
    Write-Host "`n--- Installing Packages ---" -ForegroundColor Yellow
    Install-WingetPackageIfMissing -CommandNames AutoHotkey.exe, AutoHotkey64.exe -PackageId AutoHotkey.AutoHotkey -DisplayName "AutoHotkey"
    Install-WingetPackageIfMissing -CommandNames tre.exe -PackageId ca.duan.tre-command -DisplayName "tre-command"
    Install-WingetPackageIfMissing -CommandNames PowerToys.exe -PackageId Microsoft.PowerToys -DisplayName "PowerToys"
}

# 8. Install Nerd Fonts
if ($DoFonts) {
    Write-Host "`n--- Installing Nerd Fonts ---" -ForegroundColor Yellow
    $FontDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    $RegPath = "HKCU:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Fonts"

    $FontList = @(
        @{ Name = "CaskaydiaMono Nerd Font"; ZipName = "CascadiaMono"; InstalledPattern = "CaskaydiaMono*" }
    )

    if (!(Test-Path $FontDir)) { New-Item -ItemType Directory -Path $FontDir -Force | Out-Null }

    foreach ($Font in $FontList) {
        Write-Host "`n  $($Font.Name)" -ForegroundColor Yellow

        $AlreadyInstalled = Get-ChildItem $FontDir -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -like $Font.InstalledPattern }

        if ($AlreadyInstalled) {
            Write-Host "  Already installed." -ForegroundColor Green
            continue
        }

        $Url    = "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$($Font.ZipName).zip"
        $TmpZip = Join-Path $env:TEMP "$($Font.ZipName).zip"
        $TmpDir = Join-Path $env:TEMP $Font.ZipName

        Write-Host "  Downloading from: $Url" -ForegroundColor Cyan
        try {
            Invoke-WebRequest $Url -OutFile $TmpZip -UseBasicParsing
            Expand-Archive $TmpZip -DestinationPath $TmpDir -Force

            $Installed = 0
            Get-ChildItem "$TmpDir\*.ttf" | ForEach-Object {
                $Dest = Join-Path $FontDir $_.Name
                Copy-Item $_.FullName $Dest -Force
                $RegName = $_.BaseName + " (TrueType)"
                Set-ItemProperty -Path $RegPath -Name $RegName -Value $Dest -Type String -Force
                $Installed++
            }

            Write-Host "  Installed $Installed font files." -ForegroundColor Green
        } catch {
            Write-Host "  Error installing $($Font.Name): $($_.Exception.Message)" -ForegroundColor Red
        } finally {
            Remove-Item $TmpZip, $TmpDir -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

Write-Host "`n=== Configuration Restore Complete ===" -ForegroundColor Magenta
Write-Host "Restored from: $ConfigRoot" -ForegroundColor Cyan
