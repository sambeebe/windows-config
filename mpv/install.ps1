#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Copy this folder to -Destination so mpv runs portably from there.
.DESCRIPTION
    Place this script in the mpv folder on the network drive, alongside mpv.exe
    and a portable_config\ subfolder containing your custom config (mpv.conf,
    input.conf, scripts\, etc.). Running install.ps1 mirrors the whole folder
    (minus this script) to -Destination on the local machine.
#>
[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $env:LOCALAPPDATA 'Programs\mpv'),
    [switch]$AddToPath,
    [switch]$NoAssocPrompt
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot

if (-not (Test-Path -LiteralPath (Join-Path $src 'mpv.exe'))) {
    throw "mpv.exe not found next to install.ps1 ($src). Place this script in the mpv folder."
}

Write-Host "=== mpv install ===" -ForegroundColor Magenta
Write-Host "$src -> $Destination" -ForegroundColor Cyan

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

Get-ChildItem -LiteralPath $src -Force |
    Where-Object { $_.Name -ne 'install.ps1' } |
    ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $Destination -Recurse -Force
        Write-Host "  $($_.Name)" -ForegroundColor Green
    }

if ($AddToPath) {
    $key = $Destination.TrimEnd('\').ToLowerInvariant()
    $userPath = [Environment]::GetEnvironmentVariable('PATH','User')
    $parts = if ($userPath) { $userPath.Split(';') | Where-Object { $_ } } else { @() }
    if (($parts | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() }) -notcontains $key) {
        [Environment]::SetEnvironmentVariable('PATH', (($parts + $Destination) -join ';'), 'User')
        Write-Host "Added to user PATH (open a new shell): $Destination" -ForegroundColor Green
    }
}

Write-Host "Done: $(Join-Path $Destination 'mpv.exe')" -ForegroundColor Magenta

if (-not $NoAssocPrompt) {
    Write-Host ""
    $ans = Read-Host "Make mpv the default for common video files (.mp4 .mov .mkv .webm .avi .m4v .wmv .flv)? [y/N]"
    if ($ans -match '^(y|yes)$') {
        $mpvPath = Join-Path $Destination 'mpv.exe'
        $exts = '.mp4','.mov','.mkv','.webm','.avi','.m4v','.wmv','.flv'

        # Per-user app registration. No admin needed; HKCU only.
        $appKey = 'HKCU:\Software\Classes\Applications\mpv.exe'
        New-Item -Path $appKey -Force | Out-Null
        Set-ItemProperty -Path $appKey -Name 'FriendlyAppName' -Value 'mpv'
        New-Item -Path "$appKey\shell\open\command" -Force | Out-Null
        Set-Item -LiteralPath "$appKey\shell\open\command" -Value ('"{0}" "%1"' -f $mpvPath)

        $supported = "$appKey\SupportedTypes"
        New-Item -Path $supported -Force | Out-Null
        foreach ($ext in $exts) { Set-ItemProperty -Path $supported -Name $ext -Value '' }

        # Add mpv to each extension's "Open with" list.
        foreach ($ext in $exts) {
            $owl = "HKCU:\Software\Classes\$ext\OpenWithList"
            New-Item -Path $owl -Force | Out-Null
            Set-ItemProperty -Path $owl -Name 'a' -Value 'mpv.exe'
            Set-ItemProperty -Path $owl -Name 'MRUList' -Value 'a'
        }

        Write-Host "Registered mpv. Windows requires one click to confirm the default —" -ForegroundColor Green
        Write-Host "opening Default Apps settings; find 'mpv' and set it as default." -ForegroundColor Green
        Start-Process 'ms-settings:defaultapps'
    }
}
