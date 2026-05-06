#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Offline mpv installer + config deploy.
.DESCRIPTION
    If mpv-bin\ exists next to this script, copies it to -Destination and writes
    the config to <Destination>\portable_config. Otherwise (or with -ConfigOnly)
    just deploys config: to <mpvDir>\portable_config if mpv is on PATH, else to
    %APPDATA%\mpv.

    Bundle prep (one-time, with internet): drop a portable mpv build (mpv.exe at
    top of folder) next to install.ps1 as mpv-bin\.
#>
[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $env:LOCALAPPDATA 'Programs\mpv'),
    [string]$MpvBin = (Join-Path $PSScriptRoot 'mpv-bin'),
    [switch]$ConfigOnly,
    [switch]$AddToPath,
    [switch]$NoBackup
)

$ErrorActionPreference = 'Stop'
$src = $PSScriptRoot
$items = @('mpv.conf','input.conf','mpv_settings.lua','scripts') |
    Where-Object { Test-Path -LiteralPath (Join-Path $src $_) }
if (-not $items) { throw "No config files found next to install.ps1." }

function Copy-Config([string]$Target) {
    if ((Test-Path -LiteralPath $Target) -and -not $NoBackup) {
        $bak = "$Target.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
        Copy-Item -LiteralPath $Target -Destination $bak -Recurse -Force
        Write-Host "Backup: $bak" -ForegroundColor Yellow
    }
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    foreach ($i in $items) {
        $tp = Join-Path $Target $i
        if (Test-Path -LiteralPath $tp) { Remove-Item -LiteralPath $tp -Recurse -Force }
        Copy-Item -LiteralPath (Join-Path $src $i) -Destination $tp -Recurse -Force
        Write-Host "  $i" -ForegroundColor Green
    }
}

Write-Host "=== mpv install ===" -ForegroundColor Magenta

if (-not $ConfigOnly -and (Test-Path -LiteralPath $MpvBin)) {
    $exe = Get-ChildItem -LiteralPath $MpvBin -Filter mpv.exe -Recurse -File | Select-Object -First 1
    if (-not $exe) { throw "mpv-bin\ has no mpv.exe." }
    $root = $exe.Directory.FullName

    Write-Host "Bundle: $root -> $Destination" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $Destination -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $root '*') -Destination $Destination -Recurse -Force
    Copy-Config (Join-Path $Destination 'portable_config')

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
    return
}

# Config-only.
$mpv = Get-Command mpv -ErrorAction SilentlyContinue
$target = if ($mpv) { Join-Path (Split-Path -Parent $mpv.Source) 'portable_config' }
          else      { Join-Path $env:APPDATA 'mpv' }
Write-Host "Config -> $target" -ForegroundColor Cyan
Copy-Config $target
Write-Host "Done. Restart mpv." -ForegroundColor Magenta
