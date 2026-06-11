#!/usr/bin/env pwsh
#Requires -Version 5.1
<#
.SYNOPSIS
    Launch all AutoHotkey scripts in this repo.
.EXAMPLE
    .\launch-ahks.ps1
.EXAMPLE
    .\launch-ahks.ps1 -Restart
.EXAMPLE
    .\launch-ahks.ps1 -Exclude temp.ahk
#>
[CmdletBinding(SupportsShouldProcess=$true)]
param(
    [string]$AhkDir = (Join-Path $PSScriptRoot "ahk"),
    [string[]]$Exclude = @(),
    [switch]$Restart
)

$ErrorActionPreference = "Stop"

function Resolve-FirstExistingPath {
    param([string[]]$Candidates)

    foreach ($candidate in $Candidates | Where-Object { $_ } | Select-Object -Unique) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
}

function Resolve-AutoHotkeyInstall {
    $launcherCandidates = @()
    $v1Candidates = @()
    $v2Candidates = @()

    foreach ($root in @($env:ProgramFiles, ${env:ProgramFiles(x86)}) | Where-Object { $_ }) {
        $installRoot = Join-Path $root "AutoHotkey"
        $launcherCandidates += Join-Path $installRoot "AutoHotkey.exe"
        $v2Candidates += Join-Path $installRoot "v2\AutoHotkey64.exe"
        $v2Candidates += Join-Path $installRoot "v2\AutoHotkey.exe"
        $v1Candidates += Get-ChildItem -LiteralPath $installRoot -Directory -Filter "v1*" -ErrorAction SilentlyContinue |
            Sort-Object Name -Descending |
            ForEach-Object { Join-Path $_.FullName "AutoHotkeyU64.exe" }
    }

    foreach ($name in @("AutoHotkey.exe", "AutoHotkey64.exe", "AutoHotkeyU64.exe", "AutoHotkey32.exe")) {
        $command = Get-Command $name -ErrorAction SilentlyContinue
        if ($command) {
            switch -Wildcard ($name) {
                "AutoHotkey.exe" { $launcherCandidates += $command.Source }
                "AutoHotkeyU64.exe" { $v1Candidates += $command.Source }
                default { $v2Candidates += $command.Source }
            }
        }
    }

    $install = [pscustomobject]@{
        Launcher = Resolve-FirstExistingPath $launcherCandidates
        V1 = Resolve-FirstExistingPath $v1Candidates
        V2 = Resolve-FirstExistingPath $v2Candidates
    }

    if (-not ($install.Launcher -or $install.V1 -or $install.V2)) {
        throw "AutoHotkey was not found. Install it first, or run .\restore-config.ps1 -Installs."
    }

    $install
}

function Get-RunningAutoHotkeyProcesses {
    $names = @("AutoHotkey.exe", "AutoHotkey64.exe", "AutoHotkeyU64.exe", "AutoHotkey32.exe")
    try {
        $filter = ($names | ForEach-Object { "Name = '$_'" }) -join " OR "
        Get-CimInstance Win32_Process -Filter $filter |
            Where-Object { $names -contains $_.Name -and $_.CommandLine }
    } catch {
        Write-Warning "Could not inspect running AutoHotkey command lines: $($_.Exception.Message)"
        @()
    }
}

function Get-ProcessesForScript {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptPath,
        [Parameter(Mandatory=$true)]$Processes
    )

    $escapedPath = [regex]::Escape($ScriptPath)
    $Processes | Where-Object { $_.CommandLine -match $escapedPath }
}

function Quote-Argument {
    param([Parameter(Mandatory=$true)][string]$Value)
    '"' + $Value.Replace('"', '\"') + '"'
}

function Get-AhkMajorVersion {
    param([Parameter(Mandatory=$true)][string]$ScriptPath)

    $content = Get-Content -LiteralPath $ScriptPath -Raw

    if ($content -match "(?im)^\s*#Requires\s+AutoHotkey\s+v?([12])") {
        return [int]$Matches[1]
    }

    $v1Syntax = @(
        "(?im)^\s*#IfWinActive\b",
        "(?im)^\s*\w+\s*,",
        "(?im)::\s*(Send|Click|Run|MsgBox|ControlGet|SendInput|SendRaw)\s+[^(`"]",
        "(?im)^\s*return\s*$"
    )

    foreach ($pattern in $v1Syntax) {
        if ($content -match $pattern) {
            return 1
        }
    }

    0
}

function Get-AutoHotkeyForScript {
    param(
        [Parameter(Mandatory=$true)]$Install,
        [Parameter(Mandatory=$true)][string]$ScriptPath
    )

    switch (Get-AhkMajorVersion -ScriptPath $ScriptPath) {
        1 {
            if ($Install.V1) { return $Install.V1 }
            throw "Script requires or appears to use AutoHotkey v1 syntax, but no v1 executable was found: $ScriptPath"
        }
        2 {
            if ($Install.V2) { return $Install.V2 }
            throw "Script requires AutoHotkey v2, but no v2 executable was found: $ScriptPath"
        }
        default {
            if ($Install.Launcher) { return $Install.Launcher }
            if ($Install.V2) { return $Install.V2 }
            return $Install.V1
        }
    }
}

if (-not (Test-Path -LiteralPath $AhkDir)) {
    throw "AHK directory not found: $AhkDir"
}

$autoHotkeyInstall = Resolve-AutoHotkeyInstall
$scripts = Get-ChildItem -LiteralPath $AhkDir -Filter "*.ahk" -File | Sort-Object Name

if ($Exclude.Count -gt 0) {
    $scripts = $scripts | Where-Object {
        $script = $_
        -not ($Exclude | Where-Object { $script.Name -like $_ -or $script.BaseName -like $_ })
    }
}

if (-not $scripts) {
    Write-Host "No AutoHotkey scripts found in: $AhkDir" -ForegroundColor Yellow
    return
}

$runningProcesses = @(Get-RunningAutoHotkeyProcesses)
$started = 0
$skipped = 0

if ($autoHotkeyInstall.Launcher) { Write-Host "AutoHotkey launcher: $($autoHotkeyInstall.Launcher)" -ForegroundColor Cyan }
if ($autoHotkeyInstall.V1) { Write-Host "AutoHotkey v1: $($autoHotkeyInstall.V1)" -ForegroundColor Cyan }
if ($autoHotkeyInstall.V2) { Write-Host "AutoHotkey v2: $($autoHotkeyInstall.V2)" -ForegroundColor Cyan }
Write-Host "AHK directory: $AhkDir" -ForegroundColor Cyan

foreach ($script in $scripts) {
    $scriptPath = (Resolve-Path -LiteralPath $script.FullName).Path
    $autoHotkey = Get-AutoHotkeyForScript -Install $autoHotkeyInstall -ScriptPath $scriptPath
    $matches = @(Get-ProcessesForScript -ScriptPath $scriptPath -Processes $runningProcesses)

    if ($matches.Count -gt 0) {
        if (-not $Restart) {
            Write-Host "Already running: $($script.Name)" -ForegroundColor DarkYellow
            $skipped++
            continue
        }

        foreach ($process in $matches) {
            if ($PSCmdlet.ShouldProcess("$($script.Name) PID $($process.ProcessId)", "stop existing AutoHotkey process")) {
                Stop-Process -Id $process.ProcessId -Force
            }
        }
    }

    $autoHotkeyName = Split-Path $autoHotkey -Leaf
    if ($PSCmdlet.ShouldProcess($script.Name, "launch with $autoHotkeyName")) {
        Start-Process -FilePath $autoHotkey -ArgumentList (Quote-Argument $scriptPath) -WorkingDirectory $script.DirectoryName | Out-Null
        Write-Host "Launched: $($script.Name) via $autoHotkeyName" -ForegroundColor Green
        $started++
    }
}

Write-Host "Done. Started: $started. Skipped already running: $skipped." -ForegroundColor Green
