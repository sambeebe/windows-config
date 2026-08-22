#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Restore Windows configuration files from this repo to their system locations
.DESCRIPTION
    Reverse of sync-config.ps1: copies PowerShell profile, Neovim config, Windows Terminal
    settings, and AutoHotkey scripts from this repo back out to their live system locations.

    By default shows an interactive menu to pick which sections to restore. Use -All to
    restore everything non-interactively, or pass any combination of -Profile, -Nvim,
    -WinTerm, -Ahk, -Mpv, -PowerToys, -Installs, -Tweaks, -Agents to restore specific sections.
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
    [switch]$Fonts,
    [switch]$Ffmpeg,
    [switch]$PowerToysInstall,
    [switch]$Tweaks,
    [switch]$Agents
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
        & $Winget.Source install --id $PackageId --exact --accept-package-agreements --accept-source-agreements 2>&1 | ForEach-Object { Write-Host $_ }
        $code = $LASTEXITCODE

        # winget exit codes that mean "nothing to do" — treat as success so the
        # restore loop keeps going on machines where the package is already current.
        $okCodes = @(
            0,
            -1978335189,  # APPINSTALLER_CLI_ERROR_UPDATE_NOT_APPLICABLE (no update)
            -1978335135,  # APPINSTALLER_CLI_ERROR_PACKAGE_ALREADY_INSTALLED
            -1978334975   # APPINSTALLER_CLI_ERROR_NO_APPLICABLE_INSTALLER (sometimes for already-installed)
        )
        if ($okCodes -contains $code) {
            Write-Host "$DisplayName is up to date." -ForegroundColor Green
        } else {
            Write-Host "Failed to install $DisplayName (exit code $code). Continuing." -ForegroundColor Red
        }
    } catch {
        Write-Host "Error installing ${DisplayName}: $($_.Exception.Message). Continuing." -ForegroundColor Red
    }
}

# Decide which sections to run
$AnySwitch = $All -or $Profile -or $Nvim -or $WinTerm -or $Ahk -or $Mpv -or $PowerToys -or $Installs -or $Fonts -or $Ffmpeg -or $PowerToysInstall -or $Tweaks -or $Agents
if ($All) {
    # -All intentionally excludes PowerToysInstall (heavy update); pass it explicitly when wanted.
    $DoProfile = $true; $DoNvim = $true; $DoWinTerm = $true; $DoAhk = $true; $DoMpv = $true; $DoPowerToys = $true; $DoInstalls = $true; $DoFonts = $true; $DoFfmpeg = $true; $DoPowerToysInstall = $false; $DoTweaks = $true; $DoAgents = $true
} elseif ($AnySwitch) {
    $DoProfile = [bool]$Profile
    $DoNvim = [bool]$Nvim
    $DoWinTerm = [bool]$WinTerm
    $DoAhk = [bool]$Ahk
    $DoMpv = [bool]$Mpv
    $DoPowerToys = [bool]$PowerToys
    $DoInstalls = [bool]$Installs
    $DoFonts = [bool]$Fonts
    $DoFfmpeg = [bool]$Ffmpeg
    $DoPowerToysInstall = [bool]$PowerToysInstall
    $DoTweaks = [bool]$Tweaks
    $DoAgents = [bool]$Agents
} else {
    Write-Host "`nSelect what to restore:" -ForegroundColor Yellow
    Write-Host "  1) PowerShell profile"
    Write-Host "  2) Neovim config"
    Write-Host "  3) Windows Terminal settings"
    Write-Host "  4) AutoHotkey scripts"
    Write-Host "  5) mpv config"
    Write-Host "  6) PowerToys settings"
    Write-Host "  7) Installs (AutoHotkey, tre-command, zoxide, fzf)"
    Write-Host "  8) Fonts (CaskaydiaMono Nerd Font)"
    Write-Host "  9) ffmpeg (>= 8.1, user PATH)"
    Write-Host " 10) PowerToys install/update (heavy; not included in 'All')"
    Write-Host " 11) Windows tweaks (dark mode, animation effects off, taskbar End Task)"
    Write-Host " 12) Agent configs (Claude Code, Codex, opencode)"
    Write-Host "  A) All (excludes PowerToys install)"
    Write-Host "  Q) Quit"
    Write-Host "Enter selection (e.g. '1,3' or 'A'):" -ForegroundColor Cyan -NoNewline
    $Choice = (Read-Host).Trim().ToUpper()

    if ($Choice -eq 'Q' -or [string]::IsNullOrWhiteSpace($Choice)) {
        Write-Host "Cancelled." -ForegroundColor Yellow
        return
    }

    $DoProfile = $false; $DoNvim = $false; $DoWinTerm = $false; $DoAhk = $false; $DoMpv = $false; $DoPowerToys = $false; $DoInstalls = $false; $DoFonts = $false; $DoFfmpeg = $false; $DoPowerToysInstall = $false; $DoTweaks = $false; $DoAgents = $false
    if ($Choice -eq 'A') {
        $DoProfile = $true; $DoNvim = $true; $DoWinTerm = $true; $DoAhk = $true; $DoMpv = $true; $DoPowerToys = $true; $DoInstalls = $true; $DoFonts = $true; $DoFfmpeg = $true; $DoTweaks = $true; $DoAgents = $true
    } else {
        $Parts = $Choice -split '[,\s]+' | Where-Object { $_ }
        foreach ($P in $Parts) {
            switch ($P) {
                '1'  { $DoProfile = $true }
                '2'  { $DoNvim = $true }
                '3'  { $DoWinTerm = $true }
                '4'  { $DoAhk = $true }
                '5'  { $DoMpv = $true }
                '6'  { $DoPowerToys = $true }
                '7'  { $DoInstalls = $true }
                '8'  { $DoFonts = $true }
                '9'  { $DoFfmpeg = $true }
                '10' { $DoPowerToysInstall = $true }
                '11' { $DoTweaks = $true }
                '12' { $DoAgents = $true }
                default { Write-Host "Ignoring unknown selection: $P" -ForegroundColor Red }
            }
        }
    }

    if (-not ($DoProfile -or $DoNvim -or $DoWinTerm -or $DoAhk -or $DoMpv -or $DoPowerToys -or $DoInstalls -or $DoFonts -or $DoFfmpeg -or $DoPowerToysInstall -or $DoTweaks -or $DoAgents)) {
        Write-Host "Nothing selected. Cancelled." -ForegroundColor Yellow
        return
    }
}

# 1. Restore PowerShell profile
if ($DoProfile) {
    Write-Host "`n--- Restoring PowerShell Profile ---" -ForegroundColor Yellow
    $ProfileSource = Join-Path $ConfigRoot "pwsh\Microsoft.PowerShell_profile.ps1"
    $ProfileTarget = if ($PROFILE -and $PROFILE.CurrentUserCurrentHost) {
        $PROFILE.CurrentUserCurrentHost
    } else {
        $DocsDir = [Environment]::GetFolderPath('MyDocuments')
        $PwshSubDir = if ($PSVersionTable.PSEdition -eq 'Core') { 'PowerShell' } else { 'WindowsPowerShell' }
        Join-Path $DocsDir "$PwshSubDir\Microsoft.PowerShell_profile.ps1"
    }
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
        "input.conf",
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
    # PowerToys is intentionally NOT in this bundle — its update is heavy.
    # Use option 10 / -PowerToysInstall to install or update it.
    # Note: don't name this $Installs — PowerShell variable names are case-insensitive,
    # so it would collide with the [switch]$Installs parameter and fail to convert.
    $InstallList = @(
        @{ CommandNames = @('AutoHotkey.exe','AutoHotkey64.exe'); PackageId = 'AutoHotkey.AutoHotkey'; DisplayName = 'AutoHotkey' },
        @{ CommandNames = @('tre.exe');                            PackageId = 'duan.tre';              DisplayName = 'tre-command' },
        @{ CommandNames = @('zoxide.exe');                         PackageId = 'ajeetdsouza.zoxide';    DisplayName = 'zoxide' },
        @{ CommandNames = @('fzf.exe');                            PackageId = 'junegunn.fzf';          DisplayName = 'fzf' }
    )
    foreach ($pkg in $InstallList) {
        try {
            Install-WingetPackageIfMissing -CommandNames $pkg.CommandNames -PackageId $pkg.PackageId -DisplayName $pkg.DisplayName -ErrorAction Continue
        } catch {
            Write-Host "Skipping $($pkg.DisplayName): $($_.Exception.Message)" -ForegroundColor Red
        }
    }
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

# 9. Install / update ffmpeg (>= 8.1)
if ($DoFfmpeg) {
    Write-Host "`n--- Installing ffmpeg (>= 8.1) ---" -ForegroundColor Yellow
    $FfmpegScript = Join-Path $ConfigRoot "pwsh\install-ffmpeg.ps1"
    if (Test-Path $FfmpegScript) {
        try {
            & $FfmpegScript
        } catch {
            Write-Host "Error running install-ffmpeg.ps1: $($_.Exception.Message). Continuing." -ForegroundColor Red
        }
    } else {
        Write-Host "Warning: install-ffmpeg.ps1 not found at $FfmpegScript" -ForegroundColor Red
    }
}

# 10. Install / update PowerToys (heavy; opt-in)
if ($DoPowerToysInstall) {
    Write-Host "`n--- Installing PowerToys (heavy) ---" -ForegroundColor Yellow
    try {
        Install-WingetPackageIfMissing -CommandNames PowerToys.exe -PackageId Microsoft.PowerToys -DisplayName "PowerToys" -ErrorAction Continue
    } catch {
        Write-Host "Skipping PowerToys: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# 11. Windows tweaks: dark mode, animation effects off, taskbar "End Task"
if ($DoTweaks) {
    Write-Host "`n--- Applying Windows Tweaks ---" -ForegroundColor Yellow

    function Set-RegistryValue {
        param(
            [Parameter(Mandatory=$true)][string]$Path,
            [Parameter(Mandatory=$true)][string]$Name,
            [Parameter(Mandatory=$true)]$Value,
            [ValidateSet('DWord','String')][string]$Type = 'DWord',
            [string]$Label
        )
        if (-not $Label) { $Label = $Name }
        try {
            if (!(Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
            New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
            Write-Host "  $Label" -ForegroundColor Green
        } catch {
            Write-Host "  Failed: $Label - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Win32 helpers: apply the animation setting live and tell running apps the theme changed.
    if (-not ('WinTweakNative' -as [type])) {
        try {
            Add-Type -Namespace '' -Name 'WinTweakNative' -MemberDefinition @'
[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true)]
public static extern bool SystemParametersInfo(uint uiAction, uint uiParam, System.IntPtr pvParam, uint fWinIni);

[System.Runtime.InteropServices.DllImport("user32.dll", SetLastError = true, CharSet = System.Runtime.InteropServices.CharSet.Auto)]
public static extern System.IntPtr SendMessageTimeout(System.IntPtr hWnd, uint Msg, System.IntPtr wParam, string lParam, uint fuFlags, uint uTimeout, out System.UIntPtr lpdwResult);
'@ -ErrorAction Stop
        } catch {
            Write-Host "  Note: could not load Win32 helpers, applying registry values only." -ForegroundColor Yellow
        }
    }

    # --- Dark mode (apps + system chrome) ---
    Write-Host "`n  Dark mode:" -ForegroundColor Cyan
    $PersonalizeKey = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-RegistryValue -Path $PersonalizeKey -Name 'AppsUseLightTheme'   -Value 0 -Label 'Apps set to dark'
    Set-RegistryValue -Path $PersonalizeKey -Name 'SystemUsesLightTheme' -Value 0 -Label 'Taskbar/Start set to dark'

    # --- Animation effects off (Settings > Accessibility > Visual effects) ---
    # This toggle and nothing else: it leaves MinAnimate, TaskbarAnimations and the
    # Performance Options preset (VisualFXSetting) alone, exactly as Windows does.
    Write-Host "`n  Animation effects:" -ForegroundColor Cyan
    $AnimationSet = $false
    if ('WinTweakNative' -as [type]) {
        # SPI_SETCLIENTAREAANIMATION (0x1043) with pvParam = 0 is that toggle, off.
        # SPIF_UPDATEINIFILE|SPIF_SENDCHANGE = 3 persists it and notifies running apps.
        try {
            $AnimationSet = [WinTweakNative]::SystemParametersInfo(0x1043, 0, [System.IntPtr]::Zero, 3)
            if ($AnimationSet) { Write-Host "  Animation effects off" -ForegroundColor Green }
        } catch {
            Write-Host "  SystemParametersInfo failed: $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    if (-not $AnimationSet) {
        # Fallback: the toggle is backed by bit 0x02 of byte 4 of UserPreferencesMask.
        # Takes effect at next sign-in rather than immediately.
        try {
            $DesktopKey = "HKCU:\Control Panel\Desktop"
            $Mask = (Get-ItemProperty -Path $DesktopKey -Name 'UserPreferencesMask' -ErrorAction Stop).UserPreferencesMask
            if ($Mask.Count -ge 5) {
                $Mask[4] = $Mask[4] -band 0xFD
                Set-ItemProperty -Path $DesktopKey -Name 'UserPreferencesMask' -Value $Mask -Force
                Write-Host "  Animation effects off (registry; applies at next sign-in)" -ForegroundColor Green
            } else {
                Write-Host "  Failed: UserPreferencesMask is shorter than expected" -ForegroundColor Red
            }
        } catch {
            Write-Host "  Failed: animation effects - $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # --- Taskbar right-click "End task" ---
    Write-Host "`n  Taskbar End Task:" -ForegroundColor Cyan
    Set-RegistryValue -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings" -Name 'TaskbarEndTask' -Value 1 -Label 'End task enabled in taskbar right-click menu'

    # Nudge running apps to pick up the new theme.
    if ('WinTweakNative' -as [type]) {
        $Result = [System.UIntPtr]::Zero
        try {
            # HWND_BROADCAST = 0xFFFF, WM_SETTINGCHANGE = 0x1A, SMTO_ABORTIFHUNG = 0x2
            [void][WinTweakNative]::SendMessageTimeout([System.IntPtr]0xFFFF, 0x1A, [System.IntPtr]::Zero, 'ImmersiveColorSet', 2, 1000, [ref]$Result)
        } catch { }
    }

    Write-Host "`n  Applied. Restart Explorer (or sign out) for the taskbar changes to show." -ForegroundColor Yellow
    Write-Host "  Restart Explorer now with: Stop-Process -Name explorer -Force" -ForegroundColor Cyan
}

# 12. Restore CLI agent configs (Claude Code, Codex, opencode, ...)
if ($DoAgents) {
    Write-Host "`n--- Restoring Agent Configs ---" -ForegroundColor Yellow
    $AgentsRoot = Join-Path $ConfigRoot "agents"
    $ManifestPath = Join-Path $AgentsRoot "manifest.txt"

    # Equivalent of the Linux script's `diff -rq`: identical entries are left alone so
    # repeated restores do not pile up backup copies.
    function Test-ContentEqual {
        param([Parameter(Mandatory=$true)][string]$Left, [Parameter(Mandatory=$true)][string]$Right)
        if (!(Test-Path $Left) -or !(Test-Path $Right)) { return $false }
        $LeftIsDir = Test-Path $Left -PathType Container
        if ($LeftIsDir -ne (Test-Path $Right -PathType Container)) { return $false }
        if (-not $LeftIsDir) { return (Get-FileHash $Left).Hash -eq (Get-FileHash $Right).Hash }

        $LeftRoot  = (Resolve-Path $Left).Path.TrimEnd('\')
        $RightRoot = (Resolve-Path $Right).Path.TrimEnd('\')
        $LeftFiles  = @(Get-ChildItem -LiteralPath $LeftRoot  -Recurse -File -Force | Sort-Object FullName)
        $RightFiles = @(Get-ChildItem -LiteralPath $RightRoot -Recurse -File -Force | Sort-Object FullName)
        if ($LeftFiles.Count -ne $RightFiles.Count) { return $false }
        for ($i = 0; $i -lt $LeftFiles.Count; $i++) {
            if ($LeftFiles[$i].FullName.Substring($LeftRoot.Length) -ne $RightFiles[$i].FullName.Substring($RightRoot.Length)) { return $false }
            if ((Get-FileHash $LeftFiles[$i].FullName).Hash -ne (Get-FileHash $RightFiles[$i].FullName).Hash) { return $false }
        }
        return $true
    }

    if (!(Test-Path $ManifestPath)) {
        Write-Host "Warning: manifest not found at $ManifestPath" -ForegroundColor Red
    } else {
        $LastTool = ''
        foreach ($Line in Get-Content -LiteralPath $ManifestPath) {
            $Trimmed = $Line.Trim()
            if (-not $Trimmed -or $Trimmed.StartsWith('#')) { continue }

            $Fields = $Trimmed -split '\|'
            if ($Fields.Count -ne 3) {
                Write-Host "Skipping malformed manifest line: $Trimmed" -ForegroundColor Red
                continue
            }
            $Tool, $RepoRel, $HomeRel = $Fields

            if ($Tool -ne $LastTool) {
                Write-Host "`n  $Tool" -ForegroundColor Cyan
                $LastTool = $Tool
            }

            $HomeRelWin = $HomeRel -replace '/', '\'
            $Source = Join-Path $AgentsRoot ($RepoRel -replace '/', '\')
            $Target = Join-Path $env:USERPROFILE $HomeRelWin

            if (!(Test-Path $Source)) {
                Write-Host "    not in repo, skipped: $RepoRel" -ForegroundColor DarkGray
                continue
            }

            try {
                if (Test-ContentEqual -Left $Source -Right $Target) {
                    Write-Host "    unchanged: ~\$HomeRelWin" -ForegroundColor DarkGray
                    continue
                }

                $TargetParent = Split-Path $Target -Parent
                if (!(Test-Path $TargetParent)) { New-Item -ItemType Directory -Path $TargetParent -Force | Out-Null }

                if (Test-Path $Target) {
                    # These files are hand-edited and the live copy can hold machine-specific
                    # settings this repo does not track, so never overwrite without a copy.
                    $Backup = "$Target.bak.$(Get-Date -Format yyyyMMddHHmmss)"
                    Copy-Item $Target $Backup -Recurse -Force
                    Write-Host "    backed up: ~\$HomeRelWin -> $(Split-Path $Backup -Leaf)" -ForegroundColor Yellow
                    Remove-Item $Target -Recurse -Force
                }

                Copy-Item $Source $Target -Recurse -Force
                Write-Host "    restored: ~\$HomeRelWin" -ForegroundColor Green
            } catch {
                Write-Host "    failed: ~\$HomeRelWin - $($_.Exception.Message)" -ForegroundColor Red
            }
        }
    }
}

Write-Host "`n=== Configuration Restore Complete ===" -ForegroundColor Magenta
Write-Host "Restored from: $ConfigRoot" -ForegroundColor Cyan
