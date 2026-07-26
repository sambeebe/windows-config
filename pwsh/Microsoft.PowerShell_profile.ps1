function nvmpv { nvim C:\Users\samue\AppData\Roaming\mpv\mpv.conf }
function nvloc { nvim (Join-Path (Split-Path $PROFILE -Parent) 'local.ps1') }

function Invoke-TabCycle {
    param([int]$Direction)

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,[ref]$cursor)

    # Determine base path from command line
    if ([string]::IsNullOrWhiteSpace($line)) {
        $base = ".\"
    }
    elseif ($line -match '^\.\\(.*\\)?') {
        $base = ".\" + $Matches[1]
    }
    else {
        if ($Direction -gt 0) {
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompleteNext()
        } else {
            [Microsoft.PowerShell.PSConsoleReadLine]::TabCompletePrevious()
        }
        return
    }

    $resolved = Resolve-Path $base -ErrorAction SilentlyContinue
    if (-not $resolved) { return }

    $dir = $resolved.Path

    # Refresh candidate list when directory changes
    if (
        -not $script:__cycleList -or
        $script:__cycleDir -ne $dir
    ) {

        $script:__cycleDir = $dir

        $script:__cycleList =
            Get-ChildItem $dir |
            Sort-Object @{Expression={$_.PSIsContainer};Descending=$true}, Name

        $script:__cycleIndex = -1
    }

    $count = $script:__cycleList.Count
    if ($count -eq 0) { return }

    $script:__cycleIndex = ($script:__cycleIndex + $Direction) % $count
    if ($script:__cycleIndex -lt 0) { $script:__cycleIndex += $count }

    $item = $script:__cycleList[$script:__cycleIndex]

    $replacement = Join-Path $base $item.Name

    [Microsoft.PowerShell.PSConsoleReadLine]::Replace(
        0,
        $line.Length,
        $replacement
    )
}

# Tab → forward
Set-PSReadLineKeyHandler -Key Tab -ScriptBlock {
    Invoke-TabCycle 1
}

# Shift+Tab → backward
Set-PSReadLineKeyHandler -Key Shift+Tab -ScriptBlock {
    Invoke-TabCycle -1
}

# Right arrow → expand folder
Set-PSReadLineKeyHandler -Key RightArrow -ScriptBlock {

    $line = $null
    $cursor = $null
    [Microsoft.PowerShell.PSConsoleReadLine]::GetBufferState([ref]$line,[ref]$cursor)

    if ($line -like ".\*" -and (Test-Path $line -PathType Container)) {

        if (-not $line.EndsWith("\")) {
            [Microsoft.PowerShell.PSConsoleReadLine]::Insert("\")
        }

        $script:__cycleList = $null
        return
    }

    [Microsoft.PowerShell.PSConsoleReadLine]::ForwardChar()
}

# Reset state when a command runs
Set-PSReadLineOption -AddToHistoryHandler {
    $script:__cycleList = $null
    return $true
}

function y($in){
    yt-dlp $in
}
function resume {
    cd C:\Users\samue\dev\resume
    nvim Sam_Beebe_Resume.md
}
function notes {
    cd C:\Users\samue\notes
    nvim notes.txt
}

function Compare-Files {
    param(
        [Parameter(Mandatory=$true)] [string]$File1,
        [Parameter(Mandatory=$true)] [string]$File2
    )

    $h1 = (Get-FileHash -Path $File1 -Algorithm SHA256).Hash
    $h2 = (Get-FileHash -Path $File2 -Algorithm SHA256).Hash

    if ($h1 -eq $h2) {
        Write-Output "Identical"
    } else {
        Write-Output "Different"
    }
}

Set-Alias cf Compare-Files



# function Prompt {
#     $loc = $executionContext.SessionState.Path.CurrentLocation
#
#     if ($loc.Provider.Name -eq 'FileSystem') {
#         # Emit OSC 9;9 with the FULL path so Windows Terminal can track CWD for pane splits
#         $osc = "`e]9;9;`"$($loc.ProviderPath)`"`e\"
#         Write-Host $osc -NoNewline
#     }
#
#     $path = $loc.ProviderPath
#
#     # Collapse long paths like C:\Users\JohnDoe\Documents\Dev\Project -> C:\...\Project
#     $maxParts = 3
#     $parts = ($path -split '[\\/]') | Where-Object { $_ }
#     if ($parts.Count -gt $maxParts) {
#         $shortPath = "$($parts[0])\...\$($parts[-2])\$($parts[-1])"
#     } else {
#         $shortPath = $path
#     }
#
#     # Print shortened path in white
#     Write-Host $shortPath -ForegroundColor White
#
#     # New line for command input with cyan >
#     Write-Host ('>' * ($nestedPromptLevel + 1)) -ForegroundColor Cyan -NoNewline
#
#     return ' '
# }



function Prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation

    if ($loc.Provider.Name -eq 'FileSystem') {
        # Emit OSC 9;9 with the FULL path so Windows Terminal can track CWD for pane splits
        $osc = "`e]9;9;`"$($loc.ProviderPath)`"`e\"
        Write-Host $osc -NoNewline
    }

    $path = $loc.ProviderPath.TrimEnd('\', '/')
    $parts = ($path -split '[\\\\/]') | Where-Object { $_ }
    $drive = if ($parts.Count -gt 0 -and $parts[0] -match '^[A-Za-z]:$') { $parts[0] } else { $loc.Drive.Name }
    $folderParts = if ($parts.Count -gt 1) { $parts[1..($parts.Count - 1)] } else { @() }
    $folderSuffix = if ($folderParts.Count -gt 2) { $folderParts[-2..-1] } else { $folderParts }
    $folderPath = if ($folderSuffix.Count -gt 0) { $folderSuffix -join '\' } else { '\' }
    # Explicitly set the path color to white/gray, chevron in cyan
    Write-Host "[$drive]" -ForegroundColor DarkGray -NoNewline
    Write-Host " $folderPath" -ForegroundColor White -NoNewline
    Write-Host (' >' * ($nestedPromptLevel + 1)) -ForegroundColor Cyan -NoNewline

    return ' '
}


function zz { cd .. }
function zzz { cd ..\..}
function mkcd($in) { mkdir $in && cd $in }

Set-Alias nuke "C:\Program Files\Nuke15.2v5\Nuke15.2.exe"



function nn {
	nkk && nki && nkl
}
# Add to your PowerShell profile ($PROFILE)
function Stop-NukeSessions {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        # Change if you want to narrow/expand which apps are targeted
        [string]$NamePattern = 'Nuke*',

        # Preview what would be killed without actually killing
        [switch]$DryRun
    )

    $procs = Get-Process -Name $NamePattern -ErrorAction SilentlyContinue

    if (-not $procs) {
        Write-Host "No Nuke processes found matching '$NamePattern'."
        return
    }

    if ($DryRun) {
        Write-Host "Would kill $($procs.Count) process(es):"
        $procs | Select-Object Id, Name, MainWindowTitle | Format-Table -AutoSize
        return
    }

    if ($PSCmdlet.ShouldProcess(($procs | Select-Object -Expand Name -Unique) -join ', ', "Stop-Process -Force")) {
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        Write-Host "Killed $($procs.Count) Nuke process(es)." -ForegroundColor Yellow
        $procs | Select-Object Id, Name, MainWindowTitle | Format-Table -AutoSize
    }
}

# Handy alias: run `nuke-kill` to terminate all Nuke sessions
Set-Alias nkk Stop-NukeSessions

function nkt { 	& "C:\Program Files\Nuke15.2v5\Nuke15.2.exe" "C:\Users\samue\tlm\templates\TEMP_0000_int_postvis_v0000.nk"
}

function nki {
	& C:\Users\samue\tlm\scripts\nuke\install-nuke-pipeline.bat 
}
function nkl {
	& "C:\Program Files\Nuke15.2v5\Nuke15.2.exe" "C:\Users\samue\tlm\Z\Projects\Snowman\Shots\SNO\0010\postvis\nuke\SNO_0010_postvis_int_v0001.nk"
}
function runc {
    param(
        [int]$n,
        [string]$cmd
    )

    for ($i = 1; $i -le $n; $i++) {
        Write-Host "Run #$i" -ForegroundColor Cyan
        Invoke-Expression $cmd
    }
}

# if cd is run on a file, go to that file's pdir
Remove-Item Alias:cd -ErrorAction SilentlyContinue
function cd {
    [CmdletBinding(DefaultParameterSetName='Path')]
    param(
        [Parameter(Mandatory=$true, ValueFromPipeline=$true, Position=0)]
        [Alias('PSPath','Target')]
        [string]$Path
    )

    $resolvedPath = Resolve-Path -Path $Path -ErrorAction SilentlyContinue
    if ($resolvedPath) {
        if (Test-Path -Path $resolvedPath.Path -PathType Container) {
            Set-Location -Path $resolvedPath.Path
        }
        else {
            Set-Location -Path (Split-Path -Path $resolvedPath.Path -Parent)
        }
    }
    else {
        $parentDir = Split-Path -Path $Path -Parent
        if ($parentDir -and (Test-Path -Path $parentDir -PathType Container)) {
            Set-Location -Path $parentDir
        }
        else {
            Write-Warning "Cannot find path '$Path' or its parent directory"
        }
    }

}
# Invoke-Expression (&starship init powershell)

# execute Unreal .py remotely
function ru {
    param([string]$script)
    python C:\Users\samue\scripts\remote-unreal.py $script
}

#https://medium.com/@reallydontaskmetosignin/the-single-most-important-powershell-command-that-you-will-ever-learn-407daab0a18d
del alias:history -force 2> $null
function history {Get-Content (Get-PSReadlineOption).HistorySavePath
}

function e() {
    $proc = Start-Process explorer . -PassThru
    Start-Sleep -Milliseconds 800

    # Bring the window to front using AppActivate
    try {
        $shell = New-Object -ComObject Shell.Application
        $shell.Windows() | Where-Object { $_.HWND -eq $proc.MainWindowHandle } | ForEach-Object {
            $_.Visible = $true
        }

        # Alternative method using ShowWindowAsync
        Add-Type -TypeDefinition @"
            using System;
            using System.Runtime.InteropServices;
            public class User32 {
                [DllImport("user32.dll")]
                public static extern bool ShowWindowAsync(IntPtr hWnd, int nCmdShow);
                [DllImport("user32.dll")]
                public static extern bool SetForegroundWindow(IntPtr hWnd);
            }
"@ -ErrorAction SilentlyContinue

        if ($proc.MainWindowHandle -ne [IntPtr]::Zero) {
            [User32]::ShowWindowAsync($proc.MainWindowHandle, 9) # SW_RESTORE
            [User32]::SetForegroundWindow($proc.MainWindowHandle)
        }
    }
    catch {
        # Fallback: just activate any explorer window
        Get-Process explorer | Where-Object { $_.MainWindowTitle -ne "" } | ForEach-Object {
            $_.MainWindowHandle | ForEach-Object {
                [User32]::SetForegroundWindow($_)
            }
        } | Select-Object -First 1
    }
}
function gs { git status }
function gsf {
    git status --short | fzf | ForEach-Object {
        $file = ($_ -replace '^.{3}', '')
        if ($file) {
            nvim $file
        }
    }
}
function gap {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$msg)
    $m = $msg -join ' '
    git add . && git commit -m "$m" && git push
}
function ggx {
    param([int]$n = 10)
    git log --oneline --graph --decorate -n $n
}

function uz {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true, Position=0)]
        [string]$Path,
        [switch]$Delete,
        [switch]$Keep
    )

    $zip = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $zip) {
        Write-Host "File not found: $Path" -ForegroundColor Red
        return
    }
    if ([System.IO.Path]::GetExtension($zip.Path) -ne '.zip') {
        Write-Host "Not a .zip file: $($zip.Path)" -ForegroundColor Red
        return
    }

    $parent = Split-Path $zip.Path -Parent
    $base = [System.IO.Path]::GetFileNameWithoutExtension($zip.Path)
    $dest = Join-Path $parent $base

    if (Test-Path $dest) {
        Write-Host "Destination already exists: $dest" -ForegroundColor Red
        return
    }

    try {
        Expand-Archive -LiteralPath $zip.Path -DestinationPath $dest -Force
        Write-Host "Extracted to: $dest" -ForegroundColor Green
    } catch {
        Write-Host "Extraction failed: $($_.Exception.Message)" -ForegroundColor Red
        return
    }

    if ($Keep) { return }

    if ($Delete) {
        Remove-Item -LiteralPath $zip.Path -Force
        Write-Host "Deleted: $($zip.Path)" -ForegroundColor Yellow
        return
    }

    $archive = Join-Path $parent "zip_archive"
    if (!(Test-Path $archive)) {
        New-Item -ItemType Directory -Path $archive -Force | Out-Null
    }
    Move-Item -LiteralPath $zip.Path -Destination $archive -Force
    Write-Host "Archived to: $archive" -ForegroundColor Cyan
}

function n($in) { nvim $in }

function Get-FzfPathCandidate {
    param(
        [ValidateSet('Any', 'File', 'Directory')]
        [string]$Type = 'Any'
    )

    if (Get-Command fd -ErrorAction SilentlyContinue) {
        $fdArgs = @('--hidden', '--follow', '--exclude', '.git')
        switch ($Type) {
            'File' { $fdArgs += @('--type', 'f') }
            'Directory' { $fdArgs += @('--type', 'd') }
            default { $fdArgs += @('--type', 'f', '--type', 'd') }
        }

        & fd @fdArgs
        return
    }

    $items = Get-ChildItem -Force -Recurse -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]\.git([\\/]|$)' }

    switch ($Type) {
        'File' { $items = $items | Where-Object { -not $_.PSIsContainer } }
        'Directory' { $items = $items | Where-Object { $_.PSIsContainer } }
    }

    $items | ForEach-Object {
        Resolve-Path -LiteralPath $_.FullName -Relative -ErrorAction SilentlyContinue
    }
}

function Resolve-FzfPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) {
        return $null
    }

    try {
        (Resolve-Path -LiteralPath $Path -ErrorAction Stop).ProviderPath
    } catch {
        return $null
    }
}

function Select-FzfPath {
    param(
        [ValidateSet('Any', 'File', 'Directory')]
        [string]$Type = 'Any',

        [string]$Prompt = 'path> '
    )

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning 'fzf is not installed or not on PATH.'
        return $null
    }

    $selected = Get-FzfPathCandidate -Type $Type | fzf --height 40% --layout=reverse --prompt $Prompt
    Resolve-FzfPath $selected
}

function Copy-FzfPath {
    $path = Select-FzfPath -Prompt 'copy path> '
    if (-not $path) { return }

    $path | Set-Clipboard
    Write-Output "Copied: $path"
}

function Edit-FzfFile {
    $path = Select-FzfPath -Type File -Prompt 'nvim file> '
    if (-not $path) { return }

    nvim $path
}

function Open-FzfPath {
    $path = Select-FzfPath -Prompt 'explorer> '
    if (-not $path) { return }

    if (Test-Path -LiteralPath $path -PathType Container) {
        explorer.exe $path
    } else {
        explorer.exe /select,$path
    }
}

function Set-FzfLocation {
    $path = Select-FzfPath -Type Directory -Prompt 'cd> '
    if (-not $path) { return }

    Set-Location -LiteralPath $path
}

function Edit-FzfGitFile {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Write-Warning 'git is not installed or not on PATH.'
        return
    }

    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning 'fzf is not installed or not on PATH.'
        return
    }

    $selected = git status --short | fzf --height 40% --layout=reverse --prompt 'git file> '
    if ([string]::IsNullOrWhiteSpace($selected)) { return }

    $path = ($selected -replace '^.{3}', '')
    if ($path -match ' -> ') {
        $path = ($path -split ' -> ')[-1]
    }

    $resolved = Resolve-FzfPath $path
    if ($resolved) {
        nvim $resolved
    }
}

function Copy-FzfHistory {
    if (-not (Get-Command fzf -ErrorAction SilentlyContinue)) {
        Write-Warning 'fzf is not installed or not on PATH.'
        return
    }

    $historyPath = $null
    try {
        $historyPath = (Get-PSReadLineOption).HistorySavePath
    } catch {
    }

    $history = if ($historyPath -and (Test-Path -LiteralPath $historyPath)) {
        @(Get-Content -LiteralPath $historyPath -ErrorAction SilentlyContinue)
    } else {
        @(Get-History | ForEach-Object { $_.CommandLine })
    }

    $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    $commands = for ($i = $history.Count - 1; $i -ge 0; $i--) {
        $line = [string]$history[$i]
        if (-not [string]::IsNullOrWhiteSpace($line) -and $seen.Add($line)) {
            $line
        }
    }

    $selected = $commands | fzf --height 40% --layout=reverse --prompt 'history> '
    if ([string]::IsNullOrWhiteSpace($selected)) { return }

    $selected | Set-Clipboard
    Write-Output 'Copied command to clipboard.'
}

Set-Alias fc Copy-FzfPath -Force
Set-Alias fn Edit-FzfFile
Set-Alias fe Open-FzfPath
Set-Alias fcd Set-FzfLocation
Set-Alias fgf Edit-FzfGitFile
Set-Alias fh Copy-FzfHistory

function nvr {
    $latest = Get-ChildItem -File | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-Host "No files in $(Get-Location)" -ForegroundColor Yellow
        return
    }
    nvim $latest.FullName
}

function nvl { nvr }

function fnv {
    param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Query)
    $q = ($Query -join ' ')
    $env:FNV_Q = $q
    try {
        nvim -c "lua require('telescope.builtin').find_files({default_text = vim.env.FNV_Q or ''})"
    } finally {
        Remove-Item Env:FNV_Q -ErrorAction SilentlyContinue
    }
}

function nvcon() {
    cd "C:\Users\samue\AppData\Local\nvim"
    nvim "C:\Users\samue\AppData\Local\nvim\init.lua"
}
function nvpro() {nvim $profile}
function get-env {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name
    )

    [Environment]::GetEnvironmentVariable($Name, "User")
}

function set-env {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Name,

        [Parameter(Mandatory = $true, Position = 1)]
        [AllowEmptyString()]
        [string]$Value
    )

    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
    Set-Item -Path "Env:$Name" -Value $Value
    [Environment]::GetEnvironmentVariable($Name, "User")
}

function Get-RemoteCopyTarget {
    $user = $env:REMOTE_COPY_USER
    $sshHost = $env:REMOTE_COPY_HOST

    if ([string]::IsNullOrWhiteSpace($user)) {
        throw "Missing env var REMOTE_COPY_USER. Example: set-env REMOTE_COPY_USER username"
    }

    if ([string]::IsNullOrWhiteSpace($sshHost)) {
        throw "Missing env var REMOTE_COPY_HOST. Example: set-env REMOTE_COPY_HOST remote-host"
    }

    if ($user -notmatch '^[A-Za-z0-9._-]+$') {
        throw "Unsafe SSH user in REMOTE_COPY_USER: $user"
    }

    if ($sshHost -notmatch '^[A-Za-z0-9._:-]+$') {
        throw "Unsafe SSH host in REMOTE_COPY_HOST: $sshHost"
    }

    "$user@$sshHost"
}

function ConvertTo-RemoteCopyPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OriginalPath,

        [Parameter(Mandatory = $true)]
        [string]$ResolvedPath
    )

    $remoteRoot = if ($env:REMOTE_COPY_ROOT) { $env:REMOTE_COPY_ROOT.TrimEnd('/') } else { "~" }
    if ($remoteRoot -notmatch '^(~|/[A-Za-z0-9_./-]+)$' -or $remoteRoot -match '(^|/)\.\.(/|$)') {
        throw "Unsafe remote root in REMOTE_COPY_ROOT: $remoteRoot"
    }

    $relativePath = $null
    if (-not [System.IO.Path]::IsPathFullyQualified($OriginalPath)) {
        $relativePath = $OriginalPath
    } else {
        $userHomePath = (Resolve-Path -LiteralPath $env:USERPROFILE).Path.TrimEnd('\', '/')
        if ($ResolvedPath.StartsWith($userHomePath, [System.StringComparison]::OrdinalIgnoreCase)) {
            $relativePath = $ResolvedPath.Substring($userHomePath.Length).TrimStart('\', '/')
        }
    }

    if ([string]::IsNullOrWhiteSpace($relativePath)) {
        $relativePath = Split-Path -Leaf $ResolvedPath
    }

    $relativePath = $relativePath.TrimStart('.', '\', '/')
    $remotePath = "$remoteRoot/$($relativePath -replace '\\', '/')"
    $remotePath = $remotePath -replace '/+', '/'
    $remotePath = $remotePath -replace '^~/', '~/'

    if ($remotePath -match '[`"$'';&|<>\\\s\r\n]' -or $remotePath -match '(^|/)\.\.(/|$)') {
        throw "Unsafe remote path derived from local path: $remotePath"
    }

    $remotePath
}

function Copy-FileToRemote {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [Parameter(Position = 1)]
        [ValidatePattern('^[A-Za-z0-9_./~:-]+$')]
        [string]$RemotePath
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Error "Path not found: $Path"
        return
    }

    $item = Get-Item -LiteralPath $resolved.Path
    if ($item.PSIsContainer) {
        Write-Error "Expected a file, got a directory: $($item.FullName)"
        return
    }

    $target = Get-RemoteCopyTarget
    if ([string]::IsNullOrWhiteSpace($RemotePath)) {
        $RemotePath = ConvertTo-RemoteCopyPath -OriginalPath $Path -ResolvedPath $item.FullName
    }

    if ($RemotePath -match '[`"$'';&|<>\\\s\r\n]' -or $RemotePath -match '(^|/)\.\.(/|$)') {
        throw "Unsafe remote path: $RemotePath"
    }

    $remoteDir = Split-Path -Parent ($RemotePath -replace '\\', '/')
    if ([string]::IsNullOrWhiteSpace($remoteDir)) {
        $remoteDir = "~"
    }

    ssh $target "mkdir -p $remoteDir"
    if ($LASTEXITCODE -ne 0) {
        return
    }

    scp $item.FullName "${target}:$RemotePath"
}

Set-Alias cpremote Copy-FileToRemote

function Copy-ClipboardToSquidleader {
    param(
        [Parameter(Position = 0)]
        [ValidatePattern('^[A-Za-z0-9_./~:-]+$')]
        [string]$RemoteDir = "~/fromwindows"
    )

    $target = "squidleader@192.168.1.253"
    $RemoteDir = $RemoteDir.TrimEnd('/')
    if ($RemoteDir -notmatch '^(~(/[A-Za-z0-9_./-]+)?|/[A-Za-z0-9_./-]+)$' -or $RemoteDir -match '(^|/)\.\.(/|$)') {
        throw "Unsafe remote directory: $RemoteDir"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"
    $remotePath = "$RemoteDir/$timestamp.txt"
    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) "clipboard-$timestamp.txt"

    try {
        $text = Get-Clipboard -Raw
        if ($null -eq $text) {
            $text = ""
        }

        [System.IO.File]::WriteAllText($tempFile, $text, [System.Text.UTF8Encoding]::new($false))

        ssh $target "mkdir -p $RemoteDir"
        if ($LASTEXITCODE -ne 0) {
            return
        }

        scp $tempFile "${target}:$remotePath"
        if ($LASTEXITCODE -eq 0) {
            Write-Output "Sent clipboard to ${target}:$remotePath"
        }
    }
    finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}

Set-Alias cbremote Copy-ClipboardToSquidleader

function Sync-SquidHttp {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$TargetPath = ".",

        [switch]$Force,

        [string]$BaseUrl = "http://192.168.1.253:8000/"
    )

    try {
        $targetRoot = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($TargetPath)
    } catch {
        throw "Invalid target folder: $TargetPath"
    }

    if (Test-Path -LiteralPath $targetRoot -PathType Leaf) {
        throw "Target is a file, expected a folder: $targetRoot"
    }

    New-Item -ItemType Directory -Path $targetRoot -Force | Out-Null

    $baseUri = [System.Uri]::new($BaseUrl.TrimEnd("/") + "/")

    Write-Host "$($baseUri.AbsoluteUri) -> $targetRoot" -ForegroundColor DarkGray

    $counts = @{
        Downloaded = 0
        Skipped = 0
        Failed = 0
    }

    $seenDirectories = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    function ConvertFrom-SquidRelativeUriPath {
        param([Parameter(Mandatory = $true)][string]$RelativeUriPath)

        $localPath = $targetRoot
        foreach ($encodedSegment in ($RelativeUriPath.Trim("/") -split "/")) {
            if ([string]::IsNullOrWhiteSpace($encodedSegment)) {
                continue
            }

            $segment = [System.Uri]::UnescapeDataString($encodedSegment)
            if (
                [string]::IsNullOrWhiteSpace($segment) -or
                $segment -eq "." -or
                $segment -eq ".." -or
                $segment.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -ge 0
            ) {
                Write-Warning "Skipping URL with unsupported local path: $RelativeUriPath"
                return $null
            }

            $localPath = Join-Path $localPath $segment
        }

        $localPath
    }

    function Sync-SquidHttpDirectory {
        param([Parameter(Mandatory = $true)][System.Uri]$DirectoryUri)

        if (-not $seenDirectories.Add($DirectoryUri.AbsoluteUri)) {
            return
        }

        try {
            $links = (Invoke-WebRequest -Uri $DirectoryUri.AbsoluteUri -TimeoutSec 30).Links
        } catch {
            Write-Warning "Cannot read $($DirectoryUri.AbsoluteUri): $($_.Exception.Message)"
            $counts.Failed++
            return
        }

        foreach ($link in $links) {
            $href = [System.Net.WebUtility]::HtmlDecode([string]$link.href).Trim()
            if (
                [string]::IsNullOrWhiteSpace($href) -or
                $href -eq "../" -or
                $href.StartsWith("#") -or
                $href.StartsWith("?")
            ) {
                continue
            }

            try {
                $childUri = [System.Uri]::new($DirectoryUri, $href)
            } catch {
                continue
            }

            if (
                $childUri.Scheme -ne $baseUri.Scheme -or
                $childUri.Authority -ne $baseUri.Authority -or
                -not $childUri.AbsolutePath.StartsWith($baseUri.AbsolutePath, [System.StringComparison]::OrdinalIgnoreCase)
            ) {
                continue
            }

            $relativeUriPath = $childUri.AbsolutePath.Substring($baseUri.AbsolutePath.Length)
            if ([string]::IsNullOrWhiteSpace($relativeUriPath)) {
                continue
            }

            $destination = ConvertFrom-SquidRelativeUriPath $relativeUriPath
            if ([string]::IsNullOrWhiteSpace($destination)) {
                $counts.Skipped++
                continue
            }

            if ($childUri.AbsolutePath.EndsWith("/")) {
                New-Item -ItemType Directory -Path $destination -Force | Out-Null
                Sync-SquidHttpDirectory $childUri
                continue
            }

            $relativeDisplayPath = ([System.Uri]::UnescapeDataString($relativeUriPath) -replace "/", "\")
            if (-not $Force -and (Test-Path -LiteralPath $destination -PathType Leaf)) {
                Write-Host "skip  $relativeDisplayPath" -ForegroundColor DarkGray
                $counts.Skipped++
                continue
            }

            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null

            Write-Host "get   $relativeDisplayPath" -ForegroundColor Cyan
            curl.exe -fL --progress-bar -o $destination $childUri.AbsoluteUri
            if ($LASTEXITCODE -eq 0) {
                $counts.Downloaded++
            } else {
                Write-Warning "Download failed: $($childUri.AbsoluteUri)"
                Remove-Item -LiteralPath $destination -Force -ErrorAction SilentlyContinue
                $counts.Failed++
            }
        }
    }

    Sync-SquidHttpDirectory $baseUri

    Write-Host ("Done. Downloaded {0}, skipped {1}, failed {2}." -f $counts.Downloaded, $counts.Skipped, $counts.Failed) -ForegroundColor Green
}

Set-Alias squidsync Sync-SquidHttp

function sync253 {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [string]$TargetPath = ".",

        [switch]$SkipExisting
    )

    Sync-SquidHttp -TargetPath $TargetPath -BaseUrl "http://192.168.1.253:8000/" -Force:(!$SkipExisting)
}

function Apply-ClipboardGitPatch {
    $clipboard = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($clipboard)) {
        throw "Clipboard is empty."
    }

    $fencedDiff = [regex]::Match(
        $clipboard,
        '\A\s*```diff[ \t]*\r?\n(?<patch>.*)(?<newline>\r?\n)```[ \t]*\s*\z',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    if (-not $fencedDiff.Success) {
        throw "Clipboard must contain exactly one fenced diff code block."
    }

    $patch = $fencedDiff.Groups["patch"].Value + $fencedDiff.Groups["newline"].Value
    if ($patch -notmatch '(?m)^diff --git a/.+ b/.+$') {
        throw "Clipboard diff is missing a 'diff --git a/path b/path' header."
    }

    $repoRoot = & git rev-parse --show-toplevel 2>$null
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($repoRoot)) {
        throw "Current directory is not inside a Git repository."
    }
    $repoRoot = $repoRoot.Trim()

    $tempFile = Join-Path ([System.IO.Path]::GetTempPath()) ("clipboard-patch-{0}.diff" -f [guid]::NewGuid().ToString("N"))
    try {
        [System.IO.File]::WriteAllText($tempFile, $patch, [System.Text.UTF8Encoding]::new($false))

        & git -C $repoRoot apply --check -- $tempFile
        if ($LASTEXITCODE -ne 0) {
            throw "Clipboard patch failed git apply --check."
        }

        & git -C $repoRoot apply -- $tempFile
        if ($LASTEXITCODE -ne 0) {
            throw "git apply failed."
        }

        Write-Host "Applied clipboard patch in: $repoRoot" -ForegroundColor Green
    }
    finally {
        Remove-Item -LiteralPath $tempFile -Force -ErrorAction SilentlyContinue
    }
}

Set-Alias gpatch Apply-ClipboardGitPatch

function pyzip {
    param(
        [Parameter(Position = 0)]
        [string]$Path = ".",

        [switch]$Hash
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Host "Path not found: $Path" -ForegroundColor Red
        return
    }

    $target = $resolved.Path
    if (-not (Test-Path -LiteralPath $target -PathType Container)) {
        Write-Host "Not a directory: $target" -ForegroundColor Red
        return
    }

    $dirNames = @(
        "venv", ".venv", "env", ".env",
        "build", "dist", "__pycache__",
        ".pytest_cache", ".mypy_cache", ".ruff_cache",
        ".tox", ".nox", "htmlcov", ".eggs"
    )
    $filePatterns = @(
        "*.egg-info",
        "*.pyc",
        "*.pyo",
        ".coverage"
    )

    foreach ($name in $dirNames) {
        Get-ChildItem -LiteralPath $target -Directory -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -eq $name } |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Recurse -Force
                Write-Host "Removed directory: $($_.FullName)" -ForegroundColor Yellow
            }
    }

    foreach ($pattern in $filePatterns) {
        Get-ChildItem -LiteralPath $target -Recurse -Force -ErrorAction SilentlyContinue |
            Where-Object { -not $_.PSIsContainer -and $_.Name -like $pattern } |
            ForEach-Object {
                Remove-Item -LiteralPath $_.FullName -Force
                Write-Host "Removed file: $($_.FullName)" -ForegroundColor Yellow
            }
    }

    $parent = Split-Path $target -Parent
    $name = Split-Path $target -Leaf
    $zipPath = Join-Path $parent ($name + ".zip")

    if (Test-Path -LiteralPath $zipPath) {
        Remove-Item -LiteralPath $zipPath -Force
    }

    Compress-Archive -LiteralPath $target -DestinationPath $zipPath -Force

    if ($Hash) {
        $shortHash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.Substring(0, 8).ToLowerInvariant()
        $hashedZipPath = Join-Path $parent ("{0}-{1}.zip" -f $name, $shortHash)

        if (Test-Path -LiteralPath $hashedZipPath) {
            Remove-Item -LiteralPath $hashedZipPath -Force
        }

        Move-Item -LiteralPath $zipPath -Destination $hashedZipPath
        $zipPath = $hashedZipPath
    }

    Write-Host "Created zip: $zipPath" -ForegroundColor Green
}

function mi($in) {mediainfo $in}
function ffp($in) {ffprobe -hide_banner $in}
function ffs($in) {ffprobe -v error -show_streams -select_streams v:0 $in}

function fff($in) {
    ffprobe -v error -count_frames -select_streams v:0 `
        -show_entries stream=nb_read_frames `
        -of default=nokey=1:noprint_wrappers=1 $in
}

function tv {
    param(
        [Parameter(Mandatory=$true, Position=0)] [string]$Path,
        [Parameter(Position=1)] [int]$Frames = 5
    )

    $resolved = Resolve-Path -LiteralPath $Path -ErrorAction SilentlyContinue
    if (-not $resolved) {
        Write-Host "File not found: $Path" -ForegroundColor Red
        return
    }

    $src = $resolved.Path
    $dir = Split-Path $src -Parent
    $base = [System.IO.Path]::GetFileNameWithoutExtension($src)
    $ext = [System.IO.Path]::GetExtension($src)
    $out = Join-Path $dir ("{0}_trim{1}f{2}" -f $base, $Frames, $ext)

    ffmpeg -y -i $src -frames:v $Frames -c copy $out
    if ($LASTEXITCODE -ne 0) {
        ffmpeg -y -i $src -frames:v $Frames $out
    }
    Write-Host "Wrote: $out" -ForegroundColor Green
}

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView

function lsd {
    dir | Sort-Object LastWriteTime -Descending |
        Format-Table @{Label="LastWriteTime"; Expression={$_.LastWriteTime}; Width=20},
                     @{Label="Name"; Expression={$_.Name}; Width=40} -AutoSize
}

function lsn {
    dir | Sort-Object Name |
        Format-Table @{Label="LastWriteTime"; Expression={$_.LastWriteTime}; Width=20},
                     @{Label="Name"; Expression={$_.Name}; Width=40} -AutoSize
}

function lsnr {
    dir | Sort-Object Name -Descending |
        Format-Table @{Label="LastWriteTime"; Expression={$_.LastWriteTime}; Width=20},
                     @{Label="Name"; Expression={$_.Name}; Width=40} -AutoSize
}

function lss {
    dir | Sort-Object Length -Descending |
        Format-Table @{Label="Size(KB)"; Expression={[math]::Round($_.Length / 1KB,2)}; Width=10},
                     @{Label="LastWriteTime"; Expression={$_.LastWriteTime}; Width=20},
                     @{Label="Name"; Expression={$_.Name}; Width=40} -AutoSize
}

function lsext {
    dir | Sort-Object Extension |
        Format-Table @{Label="Extension"; Expression={$_.Extension}; Width=10},
                     @{Label="LastWriteTime"; Expression={$_.LastWriteTime}; Width=20},
                     @{Label="Name"; Expression={$_.Name}; Width=40} -AutoSize
}

function lsc {
    dir | Sort-Object CreationTime -Descending |
        Format-Table @{Label="CreationTime"; Expression={$_.CreationTime}; Width=20},
                     @{Label="Name"; Expression={$_.Name}; Width=40} -AutoSize
}

function lshelp {
    @"
Available directory listing helpers:

  lsd   - List by LastWriteTime (descending, newest first)
  lsn   - List by Name (ascending, A → Z)
  lsnr  - List by Name (descending, Z → A)
  lss   - List by Size (descending, largest first)
  lsext - List by Extension (ascending)
  lsc   - List by CreationTime (descending, newest first)

Aliases:
  ls -> lsd
   l -> lsd
"@
}

# Aliases
Set-Alias ls lsd
Set-Alias d  lsd
Set-Alias l  lsn


function cpath {
    param(
        [Parameter(ValueFromPipeline=$true, ValueFromRemainingArguments=$true)]
        [string]$Path
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        # No arg: use current dir
        $full = (Get-Location).Path
    } else {
        $full = (Resolve-Path -Path $Path -ErrorAction Stop).Path
    }

    $full | Set-Clipboard
    Write-Output "Copied: $full"
}

# Short alias
Set-Alias c cpath





# function prompt {
#     $pathParts = (Get-Location).Path -split '\\'
#     $lastTwo = $pathParts[-1..-1] -join '\'
#     Write-Host "$lastTwo" -NoNewline
#     Write-Host " >" -ForegroundColor Cyan -NoNewline
#     return " "
# }








# # Initialize oh-my-posh first and let it define its prompt
# oh-my-posh init pwsh --config "C:\Users\samue\oh-my-posh-main\oh-my-posh-main\themes\spaceship.omp.json" | Invoke-Expression
#
# # Save the oh-my-posh prompt function before overwriting it
# $global:OriginalPrompt = $function:prompt
#
# # Define your custom wrapper prompt
# function Prompt {
#     $loc = $executionContext.SessionState.Path.CurrentLocation
#     $str = ""
#
#     if ($loc.Provider.Name -eq "FileSystem") {
#         # OSC 9;9 escape sequence with current folder
#         $str += "`e]9;9;`"$($loc.ProviderPath)`"`e\"
#     }
#
#     # Call oh-my-posh's prompt and append it
#     $str += & $global:OriginalPrompt
#
#     return $str
# }

# zoxide — `z <partial>` jumps to a frecent dir, `zi` for interactive picker.
if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

# Per-machine overrides. Create local.ps1 next to this profile for work-only aliases/functions.
$LocalProfile = Join-Path (Split-Path $PROFILE -Parent) 'local.ps1'
if (Test-Path $LocalProfile) { . $LocalProfile }

function Get-TerminalFolderTitle {
    $location = $executionContext.SessionState.Path.CurrentLocation
    $path = if ($location.Provider.Name -eq "FileSystem") {
        $location.ProviderPath
    } else {
        $location.Path
    }

    $trimmedPath = $path.TrimEnd('\', '/')
    if ([string]::IsNullOrWhiteSpace($trimmedPath)) {
        return $path
    }

    $leaf = Split-Path -Leaf $trimmedPath
    if ([string]::IsNullOrWhiteSpace($leaf)) {
        return $trimmedPath
    }

    return $leaf
}

if ($function:prompt.ToString() -notmatch 'Set-TerminalFolderTitle') {
    $global:PromptBeforeTerminalFolderTitle = $function:prompt
}

function Set-TerminalFolderTitle {
    $title = (Get-TerminalFolderTitle) -replace [char]7, ''
    try {
        $Host.UI.RawUI.WindowTitle = $title
    } catch {
    }

    return "$([char]27)]0;$title$([char]7)"
}

function prompt {
    $titleSequence = Set-TerminalFolderTitle
    $promptText = & $global:PromptBeforeTerminalFolderTitle
    return "$titleSequence$promptText"
}
