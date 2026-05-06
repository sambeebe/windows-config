function nvmpv { nvim C:\Users\samue\AppData\Roaming\mpv\mpv.conf }

. "$env:USERPROFILE\windows-config\pwsh\display-utils.ps1"

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

    $parts = ($loc.ProviderPath -split '[\\/]') | Where-Object { $_ }
    $lastTwo = if ($parts.Count -ge 2) { ($parts[-3..-1] -join '\') } else { $parts[-1] }

    # Explicitly set the path color to white/gray, chevron in cyan
    Write-Host $lastTwo -ForegroundColor White -NoNewline
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

function nvl {
    $latest = Get-ChildItem -File | Sort-Object CreationTime -Descending | Select-Object -First 1
    if (-not $latest) {
        Write-Host "No files in $(Get-Location)" -ForegroundColor Yellow
        return
    }
    nvim $latest.FullName
}

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

function pyzip {
    param(
        [Parameter(Position = 0)]
        [string]$Path = "."
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
