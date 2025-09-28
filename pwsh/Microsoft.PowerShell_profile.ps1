function zz { cd .. }
function zzz { cd ..\..}

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

Set-PSReadLineOption -PredictionSource History
Set-PSReadLineOption -PredictionViewStyle ListView


function lsd {
    dir | Sort-Object LastWriteTime -Descending | Select-Object LastWriteTime, Name, Length
}

function sort {
	cd "C:\Users\samue\of_v0.11.2_vs2017_release\apps\myApps\Sorting2023\src"
}








# oh-my-posh init pwsh --config "C:\Users\samue\oh-my-posh-main\oh-my-posh-main\themes\spaceship.omp.json" | Invoke-Expression
#
# function Prompt {
#     $loc = $executionContext.SessionState.Path.CurrentLocation
#     $str = ""
#
#     if ($loc.Provider.Name -eq "FileSystem") {
#         # OSC 9;9 escape sequence with current folder
#         $str += "`e]9;9;`"$($loc.ProviderPath)`"`e\"
#     }
#
#     $str += "PS $loc$('>' * ($nestedPromptLevel + 1)) "
#     return $str
# }
#

# Initialize oh-my-posh first and let it define its prompt
oh-my-posh init pwsh --config "C:\Users\samue\oh-my-posh-main\oh-my-posh-main\themes\spaceship.omp.json" | Invoke-Expression

# Save the oh-my-posh prompt function before overwriting it
$global:OriginalPrompt = $function:prompt

# Define your custom wrapper prompt
function Prompt {
    $loc = $executionContext.SessionState.Path.CurrentLocation
    $str = ""

    if ($loc.Provider.Name -eq "FileSystem") {
        # OSC 9;9 escape sequence with current folder
        $str += "`e]9;9;`"$($loc.ProviderPath)`"`e\"
    }

    # Call oh-my-posh's prompt and append it
    $str += & $global:OriginalPrompt

    return $str
}

