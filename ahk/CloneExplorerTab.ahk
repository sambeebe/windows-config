#Requires AutoHotkey v2.0

; --------------------------------------------------
; Clone current Windows Explorer tab
; Hotkey: Ctrl + Shift + D  (change if you want)
; --------------------------------------------------

^+d::CloneExplorerTab()


CloneExplorerTab() {

    hwnd := WinActive("ahk_class CabinetWClass")
    if !hwnd
        return

    shellWindows := ComObject("Shell.Application").Windows

    ; Get active tab hwnd
    try activeTab := ControlGetHwnd("ShellTabWindowClass1", hwnd)

    path := ""

    ; Locate matching explorer window + active tab
    for w in shellWindows {

        if w.hwnd != hwnd
            continue

        try {
            ; IShellBrowser interface
            IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"
            shellBrowser := ComObjQuery(w, IID_IShellBrowser, IID_IShellBrowser)

            ; Query active tab hwnd
            ComCall(3, shellBrowser, "uint*", &thisTab := 0)

            if IsSet(activeTab) && thisTab != activeTab
                continue

            path := w.Document.Folder.Self.Path
            break
        }
    }

    if (path = "")
        return

    OpenExplorerTab(hwnd, path)
}


OpenExplorerTab(hwnd, path) {

    shellWindows := ComObject("Shell.Application").Windows
    oldCount := shellWindows.Count()

    ; Command used internally by Explorer to open new tab
    SendMessage(0x0111, 0xA21B, 0, "ShellTabWindowClass1", hwnd)

    ; Wait for new tab object
    while shellWindows.Count() = oldCount
        Sleep 50

    newTab := shellWindows.Item(oldCount)

    ; Navigate cloned tab
    newTab.Navigate2(path)
}
