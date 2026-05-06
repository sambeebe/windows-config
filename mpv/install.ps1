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
    [switch]$AddToPath
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
