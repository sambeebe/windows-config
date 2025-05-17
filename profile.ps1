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

function e() { explorer . }
function nvcon() {nvim "C:\Users\samue\AppData\Local\nvim\init.lua"}
function nvpro() {nvim $profile}
function mi($in) {mediainfo $in}
function ffp($in) {ffprobe -hide_banner $in}


