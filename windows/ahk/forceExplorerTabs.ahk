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
        this.PendingWindows := Map()  ; windows we hid, waiting to be turned into a tab
        this.ClaimedWindows := Map()  ; windows already dealt with, never touch them again
        this.Busy := false            ; a thread is draining Queue
        this.Queue := []              ; {path, hwnd} jobs waiting for a tab
        this.shellWindows := ComObject('Shell.Application').Windows
    }

    static Call() {
        this.MergeWindows()
        if !this.hHook {
            this.hHook := DllCall('SetWinEventHook', 'uint', 0x8000, 'uint', 0x8002, 'ptr', 0, 'ptr', this.pWinEventHook
                                , 'uint', 0, 'uint', 0, 'uint', 0x2, 'ptr')
        }
    }

    ; hwnd of the tab a shell window represents, 0 if it can't be determined
    static TabHwnd(w) {
        static IID_IShellBrowser := '{000214E2-0000-0000-C000-000000000046}'
        try {
            shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
            ComCall(3, shellBrowser, 'uint*', &thisTab:=0)
            return thisTab
        }
        return 0
    }

    ; No count sync here on purpose: ProcessWindow already retries this until a path
    ; comes back, and during a burst the sync just stalls for its whole timeout.
    static GetPath(hwnd) {
        try activeTab := ControlGetHwnd('ShellTabWindowClass1', hwnd)
        ; if the active tab can't be matched, any tab of this window beats nothing
        fallback := ''
        for w in this.shellWindows {
            try {
                if w.hwnd != hwnd
                    continue
                path := w.Document.Folder.Self.Path
                if !IsSet(activeTab) || this.TabHwnd(w) = activeTab
                    return path
                if fallback = ''
                    fallback := path
            }
        }
        return fallback
    }

    static MergeWindows() {
        windows := WinGetList('ahk_class CabinetWClass',,, 'Address: Control Panel')
        if windows.Length > 0 {
            this.FirstWindow := windows.RemoveAt(1)
            try {
                if WinGetTransparent(this.FirstWindow) = 0
                    WinSetTransparent('Off', this.FirstWindow)
            }
        }
        firstWindow := this.FirstWindow
        paths := []
        for w in this.shellWindows {
            try {
                if w.hwnd = firstWindow
                    continue
                if InStr(WinGetText(w.hwnd), 'Address: Control Panel') {
                    this.IgnoreWindows.Set(w.hwnd, 1)
                    continue
                }
                paths.Push(w.Document.Folder.Self.Path)
            }
        }
        for hwnd in windows {
            PostMessage(0x0112, 0xF060,,, hwnd)  ; 0x0112 = WM_SYSCOMMAND, 0xF060 = SC_CLOSE
            WinWaitClose(hwnd,, 5)               ; never block startup on a window that won't close
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
                    ; a window's child controls keep firing CREATE, so skip anything
                    ; already hidden, already handled, or explicitly ignored
                    if this.IgnoreWindows.Has(ancestor) || this.PendingWindows.Has(ancestor)
                        || this.ClaimedWindows.Has(ancestor)
                        return
                    if !WinExist(ancestor) || WinGetClass(ancestor) != 'CabinetWClass'
                        return
                    if ancestor = this.FirstWindow
                        return
                    ; Hide window as early as possible. Track it in PendingWindows rather
                    ; than relying on transparency as the state flag: an already-layered
                    ; window used to skip this branch and then open as its own window.
                    this.PendingWindows.Set(ancestor, 1)
                    WinSetTransparent(0, ancestor)
                    ; if SHOW never arrives, don't leave an invisible window behind
                    SetTimer(ObjBindMethod(this, 'Unhide', ancestor), -10000)
                }
            case 0x8002:  ; EVENT_OBJECT_SHOW
                try {
                    if !WinExist(hwnd) || WinGetClass(hwnd) != 'CabinetWClass'
                        return
                    if InStr(WinGetText(hwnd), 'Address: Control Panel') {
                        this.IgnoreWindows.Set(hwnd, 1)
                        this.Unhide(hwnd)
                        return
                    }
                    if !WinExist(this.FirstWindow) || this.FirstWindow = hwnd {
                        ; nothing to merge into, so this window becomes the main one
                        this.FirstWindow := hwnd
                        this.Unhide(hwnd)
                        return
                    }
                    if !this.PendingWindows.Has(hwnd)
                        return
                    ; claim it here so a repeated SHOW can't queue a second tab
                    this.PendingWindows.Delete(hwnd)
                    this.ClaimedWindows.Set(hwnd, 1)
                    SetTimer(ObjBindMethod(this, 'ProcessWindow', hwnd), -1)
                }
            case 0x8001:  ; EVENT_OBJECT_DESTROY
                if this.IgnoreWindows.Has(hwnd)
                    this.IgnoreWindows.Delete(hwnd)
                if this.PendingWindows.Has(hwnd)
                    this.PendingWindows.Delete(hwnd)
                if this.ClaimedWindows.Has(hwnd)
                    this.ClaimedWindows.Delete(hwnd)
        }
    }

    static Unhide(hwnd) {
        if this.PendingWindows.Has(hwnd)
            this.PendingWindows.Delete(hwnd)
        try WinSetTransparent('Off', hwnd)
    }

    ; Runs on its own thread, after the window has been hidden and claimed.
    static ProcessWindow(hwnd) {
        path := ''
        deadline := A_TickCount + 3000
        loop {
            if !WinExist(hwnd)
                return
            path := this.GetPath(hwnd)
            if path != '' || A_TickCount > deadline
                break
            sleep 15  ; the window may not be registered in shellWindows yet
        }
        ; If the location can't be read, give the user back a plain window
        ; instead of closing it or leaving it invisible.
        if path = '' {
            this.Unhide(hwnd)
            return
        }
        ; Hand off to whichever thread owns the queue and return immediately.
        ; Waiting for a lock here deadlocks: AHK resumes an interrupted thread
        ; only once the interrupting thread ends, so a waiter blocks the very
        ; thread it is waiting on, and both sides run out their timeouts.
        Critical(true)
        this.Queue.Push({path: path, hwnd: hwnd})
        if this.Busy {
            Critical(false)
            return
        }
        this.Busy := true
        Critical(false)
        this.DrainQueue()
    }

    ; Opens one tab per queued window, in arrival order. Nothing in here may throw,
    ; or Busy would stay set and every later window would queue up forever.
    static DrainQueue() {
        loop {
            Critical(true)
            if !this.Queue.Length {
                this.Busy := false
                Critical(false)
                return
            }
            job := this.Queue.RemoveAt(1)
            Critical(false)
            ok := false
            try ok := this.OpenTabNow(job.path)
            if !ok {
                this.Unhide(job.hwnd)  ; leave a usable window behind
                continue
            }
            try WinClose(job.hwnd)
            try {
                if WinGetMinMax(this.FirstWindow) = -1
                    WinRestore(this.FirstWindow)
            }
        }
    }

    ; number of tab controls in a window - Win32 only, no COM round trips
    static CountTabControls(hwnd) {
        n := 0
        try {
            for classNN in WinGetControls(hwnd) {
                if classNN ~= '^ShellTabWindowClass\d+'
                    n++
            }
        }
        return n
    }

    ; Wait until the shell collection agrees with the visible tab controls. Both
    ; sides are recounted every pass: the tab count was previously sampled once up
    ; front, so if a window appeared mid-wait it chased a target that had already
    ; moved and burned the full timeout every time. The timeout is short because
    ; this is a best-effort settle, not a correctness requirement - with several
    ; windows in flight the counts may never agree, and stalling here just backs
    ; up every other window waiting behind this thread.
    static WaitForSameWindowCount(timeoutMs := 400) {
        timeout := A_TickCount + timeoutMs
        loop {
            windowCount := 0
            for hwnd in WinGetList('ahk_class CabinetWClass')
                windowCount += this.CountTabControls(hwnd)
            if windowCount = this.shellWindows.Count() || A_TickCount > timeout
                return
            sleep 15
        }
    }

    ; Startup only: MergeWindows runs before the hook is installed, so nothing else
    ; can be opening tabs yet. Everything after startup goes through the queue.
    static OpenInNewTab(path) {
        ok := false
        try ok := this.OpenTabNow(path)
        return ok
    }

    static OpenTabNow(path) {
        hwnd := this.FirstWindow
        if !hwnd || !WinExist(hwnd)
            return false
        shellWindows := this.shellWindows
        this.WaitForSameWindowCount()
        ; Remember the existing tabs so the new one can be found by diffing. Indexing
        ; with Item(Count) assumed the new tab is appended and that nothing else
        ; registers meanwhile, which is how an unrelated tab got navigated away.
        known := Map()
        for w in shellWindows {
            tab := this.TabHwnd(w)
            if tab
                known.Set(tab, 1)
        }
        baseTabs := this.CountTabControls(hwnd)
        ; open a new tab (https://stackoverflow.com/a/78502949)
        try {
            SendMessage(0x0111, 0xA21B, 0, 'ShellTabWindowClass1', hwnd,,,, 3000)
        } catch {
            return false
        }
        ; Wait for the tab control to exist. Polling this in Win32 keeps the wait
        ; cheap; diffing the shell collection here instead meant a ComObjQuery per
        ; tab on every pass. Bounded because 0xA21B is undocumented and has moved
        ; between Windows builds, and an unbounded wait wedged the whole script.
        deadline := A_TickCount + 5000
        while this.CountTabControls(hwnd) <= baseTabs {
            if A_TickCount > deadline
                return false
            sleep 15
        }
        ; the control exists, so its shell window registers within a pass or two
        item := ''
        deadline := A_TickCount + 3000
        loop {
            for w in shellWindows {
                try {
                    if w.hwnd != hwnd
                        continue
                    tab := this.TabHwnd(w)
                    if !tab || known.Has(tab)  ; unreadable tab is never treated as the new one
                        continue
                    item := w
                    break
                }
            }
            if item != ''
                break
            if A_TickCount > deadline
                return false
            sleep 15
        }
        if FileExist(path) {
            try {
                item.Navigate2(path)
            } catch {
                return false
            }
        } else {
            ; matches a shell folder path such as ::{F874310E-B6B7-47DC-BC84-B9E6B38F5903}
            if path ~= 'i)^::{[0-9A-F-]+}$'
                path := 'shell:' path
            DllCall('shell32\SHParseDisplayName', 'wstr', path, 'ptr', 0, 'ptr*', &PIDL:=0, 'uint', 0, 'ptr', 0)
            if !PIDL
                return false
            byteCount := DllCall('shell32\ILGetSize', 'ptr', PIDL, 'uint')
            SAFEARRAY := Buffer(16 + 2 * A_PtrSize, 0)
            NumPut 'ushort', 1, SAFEARRAY, 0  ; cDims
            NumPut 'uint', 1, SAFEARRAY, 4  ; cbElements
            NumPut 'ptr', PIDL, SAFEARRAY, 8 + A_PtrSize  ; pvData
            NumPut 'uint', byteCount, SAFEARRAY, 8 + 2 * A_PtrSize  ; rgsabound[1].cElements
            navigated := false
            try {
                item.Navigate2(ComValue(0x2011, SAFEARRAY.ptr))
                navigated := true
            }
            DllCall('ole32\CoTaskMemFree', 'ptr', PIDL)
            if !navigated
                return false
            deadline := A_TickCount + 5000
            while A_TickCount < deadline {
                try {
                    if !item.Busy
                        break
                } catch {
                    break
                }
                sleep 15
            }
        }
        return true
    }
}
