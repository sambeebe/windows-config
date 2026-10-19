#requires -Version 7

# Ensures ffmpeg/ffprobe >= 8.1 are installed and on the user's PATH.
# Downloads gyan.dev essentials release build into $env:USERPROFILE\tools\ffmpeg.

[CmdletBinding()]
param(
    [string]$MinVersion = '8.1',
    [string]$InstallRoot = (Join-Path $env:USERPROFILE 'tools\ffmpeg'),
    [switch]$Force
)

function Get-FFmpegVersion {
    param([string]$Exe)
    if (-not (Get-Command $Exe -ErrorAction SilentlyContinue)) { return $null }
    $line = (& $Exe -version 2>$null | Select-Object -First 1)
    if ($line -match '\bversion\s+(\d+\.\d+(?:\.\d+)?)') { return [Version]$Matches[1] }
    return $null
}

function Test-VersionOK {
    param([Version]$Have, [string]$Min)
    if (-not $Have) { return $false }
    return $Have -ge [Version]$Min
}

$ffmpegVer = Get-FFmpegVersion 'ffmpeg'
$ffprobeVer = Get-FFmpegVersion 'ffprobe'

Write-Host "ffmpeg:  $(if ($ffmpegVer) { $ffmpegVer } else { '(not found)' })"
Write-Host "ffprobe: $(if ($ffprobeVer) { $ffprobeVer } else { '(not found)' })"

if (-not $Force -and (Test-VersionOK $ffmpegVer $MinVersion) -and (Test-VersionOK $ffprobeVer $MinVersion)) {
    Write-Host "Already at >= $MinVersion. Use -Force to reinstall." -ForegroundColor Green
    return
}

$url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
$tmp = Join-Path $env:TEMP ("ffmpeg-essentials-{0}.zip" -f ([guid]::NewGuid().ToString('N').Substring(0,8)))
$stage = Join-Path $env:TEMP ("ffmpeg-stage-{0}" -f ([guid]::NewGuid().ToString('N').Substring(0,8)))

Write-Host "Downloading $url" -ForegroundColor Cyan
$ProgressPreference = 'SilentlyContinue'
Invoke-WebRequest -Uri $url -OutFile $tmp -UseBasicParsing
$ProgressPreference = 'Continue'

Write-Host "Extracting..." -ForegroundColor Cyan
Expand-Archive -LiteralPath $tmp -DestinationPath $stage -Force

# Archive root is something like ffmpeg-8.1-essentials_build/
$inner = Get-ChildItem -LiteralPath $stage -Directory | Select-Object -First 1
if (-not $inner) { throw "Unexpected archive layout under $stage" }

if (Test-Path -LiteralPath $InstallRoot) {
    Write-Host "Removing old install at $InstallRoot" -ForegroundColor Yellow
    Remove-Item -LiteralPath $InstallRoot -Recurse -Force
}
$parent = Split-Path $InstallRoot -Parent
if (-not (Test-Path -LiteralPath $parent)) {
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
}
Move-Item -LiteralPath $inner.FullName -Destination $InstallRoot
Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue

$binDir = Join-Path $InstallRoot 'bin'
if (-not (Test-Path -LiteralPath (Join-Path $binDir 'ffmpeg.exe'))) {
    throw "ffmpeg.exe not found under $binDir"
}

# Add to user PATH if missing.
$userPath = [Environment]::GetEnvironmentVariable('PATH', 'User')
$parts = if ($userPath) { $userPath.Split(';') | Where-Object { $_ } } else { @() }
$normalized = $parts | ForEach-Object { $_.TrimEnd('\').ToLowerInvariant() }
if ($normalized -notcontains $binDir.TrimEnd('\').ToLowerInvariant()) {
    $newPath = (($parts + $binDir) -join ';')
    [Environment]::SetEnvironmentVariable('PATH', $newPath, 'User')
    Write-Host "Added to user PATH: $binDir" -ForegroundColor Green
} else {
    Write-Host "User PATH already contains: $binDir" -ForegroundColor DarkGray
}

# Update current session PATH.
if (($env:PATH -split ';') -notcontains $binDir) {
    $env:PATH = "$env:PATH;$binDir"
}

$newFfmpeg = Get-FFmpegVersion (Join-Path $binDir 'ffmpeg.exe')
$newFfprobe = Get-FFmpegVersion (Join-Path $binDir 'ffprobe.exe')
Write-Host ""
Write-Host "Installed ffmpeg:  $newFfmpeg" -ForegroundColor Green
Write-Host "Installed ffprobe: $newFfprobe" -ForegroundColor Green
Write-Host "Open a new shell to pick up PATH changes." -ForegroundColor Yellow
