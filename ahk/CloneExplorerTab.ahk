#Requires AutoHotkey v2.0

; --------------------------------------------------
; Clone current Windows Explorer tab
; Hotkey: Ctrl + Shift + D  (change if you want)
; --------------------------------------------------

#HotIf WinActive("ahk_class CabinetWClass")
^+d::CloneExplorerTab()
#HotIf


CloneExplorerTab() {

    hwnd := WinActive("ahk_class CabinetWClass")
    if !hwnd
        return

    shellWindows := ComObject("Shell.Application").Windows

    ; Get active tab hwnd
    try activeTab := ControlGetHwnd("ShellTabWindowClass1", hwnd)

    path := ""
    fallback := ""

    ; Locate matching explorer window + active tab
    for w in shellWindows {
        try {
            if w.hwnd != hwnd
                continue

            thisPath := w.Document.Folder.Self.Path

            if !IsSet(activeTab) || TabHwnd(w) = activeTab {
                path := thisPath
                break
            }

            ; if the active tab can't be matched, any tab of this window beats nothing
            if fallback = ""
                fallback := thisPath
        }
    }

    if (path = "")
        path := fallback

    if (path = "")
        return

    OpenExplorerTab(hwnd, path)
}


; number of tab controls in a window - Win32 only, no COM round trips
CountTabControls(hwnd) {

    n := 0

    try {
        for classNN in WinGetControls(hwnd) {
            if classNN ~= "^ShellTabWindowClass\d+"
                n++
        }
    }

    return n
}


; hwnd of the tab a shell window represents, 0 if it can't be determined
TabHwnd(w) {

    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"

    try {
        shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)
        ComCall(3, shellBrowser, "uint*", &thisTab := 0)
        return thisTab
    }

    return 0
}


OpenExplorerTab(hwnd, path) {

    shellWindows := ComObject("Shell.Application").Windows

    ; Remember the existing tabs so the new one can be found by diffing. Item(oldCount)
    ; assumed the new tab is appended and that nothing else registers meanwhile, which
    ; could hand back an unrelated tab and navigate it away.
    known := Map()
    for w in shellWindows {
        tab := TabHwnd(w)
        if tab
            known.Set(tab, 1)
    }

    baseTabs := CountTabControls(hwnd)

    ; Command used internally by Explorer to open new tab
    try {
        SendMessage(0x0111, 0xA21B, 0, "ShellTabWindowClass1", hwnd,,,, 3000)
    } catch {
        return
    }

    ; Wait for the tab control to exist. Polling this in Win32 keeps the wait cheap;
    ; diffing the shell collection here instead meant a ComObjQuery per tab on every
    ; pass. Bounded because 0xA21B is undocumented and has moved between Windows
    ; builds, and an unbounded wait would hang the script for good.
    deadline := A_TickCount + 5000
    while CountTabControls(hwnd) <= baseTabs {
        if A_TickCount > deadline
            return
        Sleep 15
    }

    ; the control exists, so its shell window registers within a pass or two
    newTab := ""
    deadline := A_TickCount + 3000
    loop {
        for w in shellWindows {
            try {
                if w.hwnd != hwnd
                    continue
                tab := TabHwnd(w)
                if !tab || known.Has(tab)  ; unreadable tab is never treated as the new one
                    continue
                newTab := w
                break
            }
        }
        if newTab != ""
            break
        if A_TickCount > deadline
            return
        Sleep 15
    }

    ; Navigate cloned tab
    try newTab.Navigate2(path)
}
