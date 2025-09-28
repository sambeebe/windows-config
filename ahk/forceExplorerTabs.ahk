; https://www.reddit.com/r/AutoHotkey/comments/1fvsm2y/force_windows_11_to_open_file_explorer_in_new_tab/
#Requires AutoHotkey v2.0

Persistent

ForceOneExplorerWindow()

class ForceOneExplorerWindow {

    static __New() {
        this.FirstWindow := 0
        this.hHook := 0
        this.pWinEventHook := CallbackCreate(ObjBindMethod(this, 'WinEventProc'),, 7)
        this.IgnoreWindows := Map()
        this.shellWindows := ComObject('Shell.Application').Windows
    }

    static Call() {
        this.MergeWindows()
        if !this.hHook {
            this.hHook := DllCall('SetWinEventHook', 'uint', 0x8000, 'uint', 0x8002, 'ptr', 0, 'ptr', this.pWinEventHook
                                , 'uint', 0, 'uint', 0, 'uint', 0x2, 'ptr')
        }
    }

    static GetPath(hwnd) {
        static IID_IShellBrowser := '{000214E2-0000-0000-C000-000000000046}'
        shellWindows := this.shellWindows
        this.WaitForSameWindowCount()
        try activeTab := ControlGetHwnd('ShellTabWindowClass1', hwnd)
        for w in shellWindows {
            if w.hwnd != hwnd
                continue
            if IsSet(activeTab) {
                shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
                ComCall(3, shellBrowser, 'uint*', &thisTab:=0)
                if thisTab != activeTab
                    continue
            }
            return w.Document.Folder.Self.Path
        }
    }

    static MergeWindows() {
        windows := WinGetList('ahk_class CabinetWClass',,, 'Address: Control Panel')
        if windows.Length > 0 {
            this.FirstWindow := windows.RemoveAt(1)
            if WinGetTransparent(this.FirstWindow) = 0 {
                WinSetTransparent("Off", this.FirstWindow)
            }
        }
        firstWindow := this.FirstWindow
        shellWindows := this.shellWindows
        paths := []
        for w in shellWindows {
            if w.hwnd = firstWindow
                continue
            if InStr(WinGetText(w.hwnd), 'Address: Control Panel') {
                this.IgnoreWindows.Set(w.hwnd, 1)
                continue
            }
            paths.push(w.Document.Folder.Self.Path)
        }
        for hwnd in windows {
            PostMessage(0x0112, 0xF060,,, hwnd)  ; 0x0112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
            WinWaitClose(hwnd)
        }
        for path in paths {
            this.OpenInNewTab(path)
        }
    }

    static WinEventProc(hWinEventHook, event, hwnd, idObject, idChild, idEventThread, dwmsEventTime) {
        Critical(-1)
        if !(idObject = 0 && idChild = 0) {
            return
        }
        switch event {
            case 0x8000:  ; EVENT_OBJECT_CREATE
                ancestor := DllCall('GetAncestor', 'ptr', hwnd, 'uint', 2, 'ptr')
                try {
                    if !this.IgnoreWindows.Has(ancestor) && WinExist(ancestor) && WinGetClass(ancestor) = 'CabinetWClass' {
                        if ancestor = this.FirstWindow
                            return
                        if WinGetTransparent(ancestor) = '' {
                            ; Hide window as early as possible
                            WinSetTransparent(0, ancestor)
                        }
                    }
                }
            case 0x8002:  ; EVENT_OBJECT_SHOW
                if WinExist(hwnd) && WinGetClass(hwnd) = 'CabinetWClass' {
                    if InStr(WinGetText(hwnd), 'Address: Control Panel') {
                        this.IgnoreWindows.Set(hwnd, 1)
                        WinSetTransparent('Off', hwnd)
                        return
                    }
                    if !WinExist(this.FirstWindow) {
                        this.FirstWindow := hwnd
                        WinSetTransparent('Off', hwnd)
                    }
                    if WinGetTransparent(hwnd) = 0 {
                        SetTimer(() => (
                            this.OpenInNewTab(this.GetPath(hwnd))
                            , WinClose(hwnd)
                            , WinGetMinMax(this.FirstWindow) = -1 && WinRestore(this.FirstWindow)
                        ), -1)
                    }
                }
            case 0x8001:  ; EVENT_OBJECT_DESTROY
                if this.IgnoreWindows.Has(hwnd)
                    this.IgnoreWindows.Delete(hwnd)
        }
    }

    static WaitForSameWindowCount() {
        shellWindows := this.shellWindows
        windowCount := 0
        for hwnd in WinGetList('ahk_class CabinetWClass') {
            for classNN in WinGetControls(hwnd) {
                if classNN ~= '^ShellTabWindowClass\d+'
                    windowCount++
            }
        }
        ; wait for window count to update
        timeout := A_TickCount + 3000
        while windowCount != shellWindows.Count() {
            sleep 50
            if A_TickCount > timeout
                break
        }
    }

    static OpenInNewTab(path) {
        this.WaitForSameWindowCount()
        hwnd := this.FirstWindow
        shellWindows := this.shellWindows
        Count := shellWindows.Count()
        ; open a new tab (https://stackoverflow.com/a/78502949)
        SendMessage(0x0111, 0xA21B, 0, 'ShellTabWindowClass1', hwnd)
        ; Wait for window count to change
        while shellWindows.Count() = Count {
            sleep 50
        }
        Item := shellWindows.Item(Count)
        if FileExist(path) {
            Item.Navigate2(Path)
        } else {
            ; matches a shell folder path such as ::{F874310E-B6B7-47DC-BC84-B9E6B38F5903}
            if path ~= 'i)^::{[0-9A-F-]+}$'
                path := 'shell:' path
            DllCall('shell32\SHParseDisplayName', 'wstr', path, 'ptr', 0, 'ptr*', &PIDL:=0, 'uint', 0, 'ptr', 0)
            byteCount := DllCall('shell32\ILGetSize', 'ptr', PIDL, 'uint')
            SAFEARRAY := Buffer(16 + 2 * A_PtrSize, 0)
            NumPut 'ushort', 1, SAFEARRAY, 0  ; cDims
            NumPut 'uint', 1, SAFEARRAY, 4  ; cbElements
            NumPut 'ptr', PIDL, SAFEARRAY, 8 + A_PtrSize  ; pvData
            NumPut 'uint', byteCount, SAFEARRAY, 8 + 2 * A_PtrSize  ; rgsabound[1].cElements
            try Item.Navigate2(ComValue(0x2011, SAFEARRAY.ptr))
            DllCall('ole32\CoTaskMemFree', 'ptr', PIDL)
            while Item.Busy {
                sleep 50
            }
        }
    }
}
