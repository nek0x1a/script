#Requires AutoHotkey v2.0
#SingleInstance Force

; Win + Shift + Q - 关闭窗口
#+q:: WinClose "A"
; Win + T - 置顶窗口
#t:: WinSetAlwaysOnTop -1, "A"

; 虚拟桌面切换
^#XButton1:: Send "{Ctrl Down}{LWin Down}{Left}{LWin Up}{Ctrl Up}"
^#XButton2:: Send "{Ctrl Down}{LWin Down}{Right}{LWin Up}{Ctrl Up}"
