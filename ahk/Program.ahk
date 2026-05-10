#Requires AutoHotkey v2.0
#SingleInstance Force

global EnvProtableApplicationPath := EnvGet("ProtableApplicationPath")
global EnvApplicationPath := EnvGet("eApplicationPath")

; Win + Shift + ` - 终端
#+`:: Run "*RunAs " A_ProgramFiles "\Alacritty\alacritty.exe"
; Win + `
#`:: {
    ThisWin := "Alacritty ahk_exe alacritty.exe"
    if WinExist(ThisWin) {
        if WinActive(ThisWin) {
            WinMinimize
        } else {
            if WinGetMinMax(ThisWin) == -1 {
                WinRestore
            }
            WinActivate
        }
    } else {
        Run A_ProgramFiles "\Alacritty\alacritty.exe"
    }
}

; Win + Shift + N - 笔记本
#+n:: Run "notepad"
; Win + N
#n:: {
    ThisWin := "ahk_class Notepad4 ahk_exe Notepad4.exe"
    if WinExist(ThisWin) {
        if WinActive(ThisWin) {
            WinMinimize
        } else {
            if WinGetMinMax(ThisWin) == -1 {
                WinRestore
            }
            WinActivate
        }
    } else {
        Run "notepad"
    }
}

; Win + B - 浏览器
#b:: {
    ThisWin := "ahk_class Chrome_WidgetWin_1 ahk_exe chrome.exe"
    if WinExist(ThisWin) {
        if WinActive(ThisWin) {
            WinMinimize
        } else {
            if WinGetMinMax(ThisWin) == -1 {
                WinRestore
            }
            WinActivate
        }
    } else {
        Run EnvProtableApplicationPath "\GoogleChrome\chrome.exe"
    }
}
