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
function n($in) { nvim $in }
function nvcon() {
    cd "C:\Users\samue\AppData\Local\nvim"
    nvim "C:\Users\samue\AppData\Local\nvim\init.lua"
}
function nvpro() {nvim $profile}
function mi($in) {mediainfo $in}
function ffp($in) {ffprobe -hide_banner $in}
function ffs($in) {ffprobe -v error -show_streams -select_streams v:0 $in}

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

