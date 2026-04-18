
#IfWinActive ahk_class CabinetWClass

MButton::
SendInput, {Ctrl down}{LButton}{Ctrl up}
return

#IfWinActive