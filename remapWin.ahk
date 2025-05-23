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
Capslock::Esc
Esc::Capslock
