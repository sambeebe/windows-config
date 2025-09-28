; Press Ctrl+Alt+T inside Explorer to open the current folder in a terminal
^!t::
    ; Get the active window's folder path
    explorerHwnd := WinActive("ahk_class CabinetWClass")
    if !explorerHwnd {
        MsgBox, 48, Error, No Explorer window is active.
        return
    }

    ; Use the same method as forceExplorerTabs.ahk to get active tab path
    currentPath := GetActiveTabPath(explorerHwnd)

    if (currentPath = "")
    {
        MsgBox, 48, Error, Could not retrieve the current folder path.
        return
    }

    ; Open PowerShell in that directory
    Run, pwsh -NoExit -Command "Set-Location -LiteralPath '%currentPath%'"
return

; Function adapted from forceExplorerTabs.ahk logic
GetActiveTabPath(hwnd) {
    static IID_IShellBrowser := "{000214E2-0000-0000-C000-000000000046}"

    shellWindows := ComObjCreate("Shell.Application").Windows

    ; Get the active tab control handle
    ControlGet, activeTab, Hwnd,, ShellTabWindowClass1, ahk_id %hwnd%

    for window in shellWindows {
        try {
            if (window.hwnd != hwnd)
                continue

            ; If we have tabs, check which one is active
            if (activeTab) {
                ; Try to get shell browser interface
                try {
                    shellBrowser := ComObjQuery(window, IID_IShellBrowser, IID_IShellBrowser)
                    if (shellBrowser) {
                        ; Get the current view's tab handle
                        DllCall(NumGet(NumGet(shellBrowser+0)+3*A_PtrSize), "Ptr", shellBrowser, "UInt*", thisTab)

                        ; If this isn't the active tab, skip it
                        if (thisTab != activeTab)
                            continue
                    }
                } catch e {
                    ; If we can't get shell browser, fall back to basic method
                }
            }

            ; Get the path from this window/tab
            return window.Document.Folder.Self.Path

        } catch e {
            continue
        }
    }

    return ""
}

; Press Ctrl+Alt+O to open parent directory of the full path in clipboard
^!o::
    ClipWait, 1
    fullPath := Clipboard

    ; Remove surrounding quotes if present
    fullPath := RegExReplace(fullPath, "^""|""$")

    if !FileExist(fullPath) {
        MsgBox, 48, Error, Clipboard does not contain a valid file or folder path.
        return
    }

    ; If it's a file, get its parent directory
    if InStr(FileExist(fullPath), "D") {
        parentDir := fullPath   ; It's already a directory
    } else {
        SplitPath, fullPath, , parentDir
    }

    if (parentDir = "")
    {
        MsgBox, 48, Error, Could not determine the parent directory.
        return
    }

    Run, explorer.exe "%parentDir%"

    ; Force the Explorer window to come to the foreground
    Sleep, 500  ; Wait for Explorer to open
    WinActivate, ahk_class CabinetWClass
    WinRestore, ahk_class CabinetWClass  ; Restore if minimized
    WinShow, ahk_class CabinetWClass     ; Ensure it's visible
return



F15::  ; F15 for Notepad++
  if WinExist("ahk_exe notepad++.exe") {
    if WinActive("ahk_exe notepad++.exe") {
      WinMinimize, ahk_exe notepad++.exe
    } else {
      WinActivate, ahk_exe notepad++.exe
    }
  } else {
    Run, C:\Program Files\Notepad++\notepad++.exe
  }
return

F20::  ; F20 for Windows Terminal
  if WinExist("ahk_exe WindowsTerminal.exe") {
    if WinActive("ahk_exe WindowsTerminal.exe") {
      WinMinimize, ahk_exe WindowsTerminal.exe
    } else {
      WinActivate, ahk_exe WindowsTerminal.exe
    }
  } else {
    Run, wt.exe
  }
return

F21::  ; F21 for Windows Explorer
  if WinExist("ahk_class CabinetWClass") {
    if WinActive("ahk_class CabinetWClass") {
      WinMinimize, ahk_class CabinetWClass
    } else {
      WinActivate, ahk_class CabinetWClass
    }
  } else {
    Run, explorer.exe
  }
return

F22::  ; F22 reserved (was Windows Terminal)
return

F23::  ; F23 for Everything search tool
  if WinExist("ahk_exe Everything.exe") {
    if WinActive("ahk_exe Everything.exe") {
      WinMinimize, ahk_exe Everything.exe
    } else {
      WinActivate, ahk_exe Everything.exe
    }
  } else {
    Run, C:\Program Files\Everything\Everything.exe
  }
return

F24::  ; F24 for Chrome
  if WinExist("ahk_exe chrome.exe") {
    if WinActive("ahk_exe chrome.exe") {
      WinMinimize, ahk_exe chrome.exe
    } else {
      WinActivate, ahk_exe chrome.exe
    }
  } else {
    Run, chrome.exe
  }


return
; Swap Escape and Caps Lock
; Capslock::Esc
; Esc::Capslock
