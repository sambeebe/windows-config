Add-Type -TypeDefinition @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
public class DisplayUtil {
    [DllImport("shcore.dll")]
    public static extern int GetDpiForMonitor(IntPtr hMonitor, int dpiType, out uint dpiX, out uint dpiY);
    [DllImport("user32.dll")]
    public static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, MonitorEnumProc fn, IntPtr data);
    [DllImport("user32.dll", CharSet=CharSet.Unicode)]
    public static extern bool GetMonitorInfo(IntPtr hMonitor, ref MonitorInfoEx info);
    [DllImport("user32.dll")]
    public static extern bool SystemParametersInfo(uint action, uint param, IntPtr pvParam, uint winIni);
    public delegate bool MonitorEnumProc(IntPtr hMon, IntPtr hdc, IntPtr rect, IntPtr data);
    [StructLayout(LayoutKind.Sequential, CharSet=CharSet.Unicode)]
    public struct MonitorInfoEx {
        public int cbSize;
        public Rect rcMonitor, rcWork;
        public uint dwFlags;
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string szDevice;
    }
    [StructLayout(LayoutKind.Sequential)]
    public struct Rect { public int L, T, R, B; }

    public static List<Tuple<IntPtr,string,int,int>> GetMonitors() {
        var list = new List<Tuple<IntPtr,string,int,int>>();
        EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (hMon, hdc, rect, data) => {
            var info = new MonitorInfoEx(); info.cbSize = Marshal.SizeOf(info);
            if (GetMonitorInfo(hMon, ref info)) {
                uint dx, dy;
                GetDpiForMonitor(hMon, 0, out dx, out dy);
                list.Add(Tuple.Create(hMon, info.szDevice, info.rcMonitor.L, (int)dx));
            }
            return true;
        }, IntPtr.Zero);
        list.Sort((a,b) => a.Item3.CompareTo(b.Item3));
        return list;
    }
}
"@ -ErrorAction SilentlyContinue

function Get-Displays {
    $regBase = "HKCU:\Control Panel\Desktop\PerMonitorSettings"
    $monitors = [DisplayUtil]::GetMonitors()
    $regKeys  = @(Get-ChildItem $regBase -ErrorAction SilentlyContinue)

    for ($i = 0; $i -lt $monitors.Count; $i++) {
        $dpi    = $monitors[$i].Item4
        $scale  = [int]($dpi / 96 * 100)
        $offset = if ($i -lt $regKeys.Count) {
            [int][System.Convert]::ToInt32((Get-ItemProperty $regKeys[$i].PSPath -Name DpiValue -EA SilentlyContinue).DpiValue)
        } else { 0 }
        [PSCustomObject]@{
            Display    = $i + 1
            Device     = $monitors[$i].Item2
            ScalePct   = "$scale%"
            DpiOffset  = $offset
        }
    }
}

function Set-Zoom {
    param(
        [int]$Display = 1,
        [Parameter(Mandatory)][ValidateSet(100,125,150,175,200,225,250,300,350)][int]$Percent
    )
    $regBase = "HKCU:\Control Panel\Desktop\PerMonitorSettings"
    $monitors = [DisplayUtil]::GetMonitors()
    $regKeys  = @(Get-ChildItem $regBase -ErrorAction SilentlyContinue)
    $idx = $Display - 1

    if ($idx -lt 0 -or $idx -ge $monitors.Count) {
        Write-Error "Display $Display not found. Run Get-Displays to list."; return
    }

    $currentDpi    = $monitors[$idx].Item4
    $currentScale  = [int]($currentDpi / 96 * 100)
    $currentOffset = [int][System.Convert]::ToInt32((Get-ItemProperty $regKeys[$idx].PSPath -Name DpiValue -EA SilentlyContinue).DpiValue)
    $recommended   = $currentScale - ($currentOffset * 25)
    $newOffset     = ($Percent - $recommended) / 25

    Set-ItemProperty $regKeys[$idx].PSPath -Name DpiValue -Value ([int]$newOffset) -Type DWord
    # Broadcast the change
    [DisplayUtil]::SystemParametersInfo(0x002A, 0, [IntPtr]::Zero, 0x03) | Out-Null
    Write-Host "Display $Display zoom set to $Percent% (DpiOffset=$newOffset). Sign out/in if apps don't update." -ForegroundColor Green
}
