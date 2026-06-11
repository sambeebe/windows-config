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

    ; Open Windows Terminal in that directory.
    Run, wt.exe -d "%currentPath%"
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

; Press Ctrl+Alt+O to open a selected/copied path in Explorer
^!o::
    rawPathText := GetSelectedTextOrClipboard()
    OpenPathTextInExplorer(rawPathText)
return

; Press Ctrl+Alt+Shift+O to copy the selected path, then open it in Explorer
^!+o::
    rawPathText := CopySelectedTextOrClipboard()
    OpenPathTextInExplorer(rawPathText)
return

OpenPathTextInExplorer(rawPathText) {
    baseDir := ""
    if WinActive("ahk_class CabinetWClass")
        baseDir := GetActiveTabPath(WinActive("ahk_class CabinetWClass"))

    fullPath := ResolvePathFromText(rawPathText, baseDir)

    if (fullPath = "") {
        MsgBox, 48, Error, Could not find a valid file or folder path in the selection or clipboard.
        return
    }

    OpenPathInExplorer(fullPath)
}

GetSelectedTextOrClipboard() {
    savedClipboard := ClipboardAll
    previousText := Clipboard

    Clipboard =
    Send, ^c
    ClipWait, 0.35

    if (Clipboard != "")
        text := Clipboard
    else
        text := previousText

    Clipboard := savedClipboard
    return text
}

CopySelectedTextOrClipboard() {
    savedClipboard := ClipboardAll
    previousText := Clipboard

    Clipboard =
    Send, ^c
    ClipWait, 0.35

    if (Clipboard != "")
        return Clipboard

    Clipboard := savedClipboard
    return previousText
}

ResolvePathFromText(rawText, baseDir := "") {
    candidates := []
    candidates.Push(rawText)

    Loop, Parse, rawText, `n, `r
    {
        line := Trim(A_LoopField)
        if (line = "")
            continue

        candidates.Push(line)
        ExtractQuotedPathCandidates(line, candidates)
        ExtractAbsolutePathCandidates(line, candidates)
    }

    for index, candidate in candidates {
        resolved := ResolvePathCandidate(candidate, baseDir)
        if (resolved != "")
            return resolved
    }

    return ""
}

ExtractQuotedPathCandidates(text, candidates) {
    pos := 1
    while (pos := RegExMatch(text, """([^""]+)""|'([^']+)'|``([^``]+)``", match, pos)) {
        if (match1 != "")
            candidates.Push(match1)
        else if (match2 != "")
            candidates.Push(match2)
        else if (match3 != "")
            candidates.Push(match3)

        pos += StrLen(match)
    }
}

ExtractAbsolutePathCandidates(text, candidates) {
    pos := 1
    pattern := "i)([A-Z]:[\\/][^<>""|?*`r`n]+|\\\\[^<>""|?*`r`n]+)"

    while (pos := RegExMatch(text, pattern, match, pos)) {
        candidates.Push(match1)
        pos += StrLen(match1)
    }
}

ResolvePathCandidate(candidate, baseDir := "") {
    path := CleanPathCandidate(candidate)
    if (path = "")
        return ""

    if FileExist(path)
        return path

    path := StripEditorLocationSuffixes(path)
    if FileExist(path)
        return path

    if (baseDir != "" && !IsAbsoluteWindowsPath(path)) {
        joinedPath := RTrim(baseDir, "\/") . "\" . path
        if FileExist(joinedPath)
            return joinedPath

        joinedPath := StripEditorLocationSuffixes(joinedPath)
        if FileExist(joinedPath)
            return joinedPath
    }

    return FindExistingPrefix(path)
}

CleanPathCandidate(candidate) {
    path := Trim(candidate, " `t`r`n""'<>")
    path := RegExReplace(path, "^\s*(at|file|path)\s+", "")
    path := RegExReplace(path, "^\s*[-*]\s+", "")

    if RegExMatch(path, "i)^file://([^/]+)/(.+)$", uri) {
        path := "\\" . uri1 . "\" . UriDecode(uri2)
    } else if RegExMatch(path, "i)^file:(//)?/?(.+)$", uri) {
        path := UriDecode(uri2)
        if RegExMatch(path, "^/[A-Z]:/")
            path := SubStr(path, 2)
    }

    path := ExpandEnvironmentStrings(path)

    if (SubStr(path, 1, 2) = "~\" || SubStr(path, 1, 2) = "~/") {
        EnvGet, userProfile, USERPROFILE
        path := userProfile . SubStr(path, 2)
    }

    if RegExMatch(path, "i)^/mnt/([a-z])/(.+)$", wsl) {
        path := wsl1 . ":\" . wsl2
    }

    if RegExMatch(path, "i)^[A-Z]:/")
        StringReplace, path, path, /, \, All

    return Trim(path, " `t`r`n""'<>.,;")
}

StripEditorLocationSuffixes(path) {
    Loop, 4 {
        original := path
        path := RegExReplace(path, ":\d+(:\d+)?$", "")
        path := RegExReplace(path, "\(\d+(,\d+)?\)$", "")
        path := RegExReplace(path, "#L\d+(-L\d+)?$", "")
        path := RegExReplace(path, "\s+\bat\s+line\s+\d+.*$", "")
        path := Trim(path, " `t`r`n""'<>.,;")

        if (path = original)
            break
    }

    return path
}

FindExistingPrefix(path) {
    candidate := StripEditorLocationSuffixes(path)

    Loop, 12 {
        if FileExist(candidate)
            return candidate

        next := RegExReplace(candidate, "\s+\S+$", "")
        if (next = candidate || next = "")
            break

        candidate := Trim(next, " `t`r`n""'<>.,;")
    }

    return ""
}

IsAbsoluteWindowsPath(path) {
    return RegExMatch(path, "i)^([A-Z]:\\|\\\\)")
}

OpenPathInExplorer(path) {
    if InStr(FileExist(path), "D") {
        Run, explorer.exe "%path%"
    } else {
        Run, explorer.exe /select`,"%path%"
    }

    Sleep, 250
    WinActivate, ahk_class CabinetWClass
    WinRestore, ahk_class CabinetWClass
    WinShow, ahk_class CabinetWClass
}

ExpandEnvironmentStrings(text) {
    VarSetCapacity(buffer, 32767 * 2)
    size := DllCall("ExpandEnvironmentStrings", "Str", text, "Str", buffer, "UInt", 32767)
    if (size > 0 && size <= 32767)
        return buffer

    return text
}

UriDecode(text) {
    text := StrReplace(text, "+", " ")
    pos := 1

    while (pos := RegExMatch(text, "i)%([0-9A-F]{2})", match, pos)) {
        char := Chr("0x" . match1)
        text := SubStr(text, 1, pos - 1) . char . SubStr(text, pos + 3)
        pos += 1
    }

    return text
}



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
