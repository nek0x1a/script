#Requires AutoHotkey v2.0

global EnvProtableApplicationPath := EnvGet("ProtableApplicationPath")
global DopusrtPath := EnvProtableApplicationPath "\DirectoryOpus\dopusrt.exe"
global TempFile := A_Temp "\dopus_path.txt"

; Alt + G - 切换文件对话框路径
!g:: {
    ; 当前活跃窗口的句柄
    activeHwnd := WinExist("A")
    ; 检查是否为标准文件对话框 (#32770 是对话框的类名)
    if !WinActive("ahk_class #32770") {
        ToolTip "❌ 当前不是文件对话框"
        SetTimer () => ToolTip(), -1000
        return
    }

    ; 获取需要跳转的目标目录
    targetPath := GetTargetPath()

    if (targetPath == "") {
        ; ToolTip "❌ 未找到有效路径"
        ; SetTimer () => ToolTip(), -1000
        return
    }

    ; 执行跳转动作
    try {
        ; 向文件对话框的“文件名”输入框 (Edit1) 写入路径并回车
        ControlFocus "Edit1", "ahk_id " activeHwnd
        ControlSetText targetPath, "Edit1", "ahk_id " activeHwnd
        ControlSend "{Enter}", "Edit1", "ahk_id " activeHwnd
        ToolTip "✅ 已跳转至: " targetPath
    } catch {
        ToolTip "❌ 跳转失败"
    }
    SetTimer () => ToolTip(), -1000
}

; 获取最后访问的路径
GetTargetPath() {
    dopusPath := GetDopusPath()
    return dopusPath != "" ? dopusPath : GetExplorerPath()
}
; 获取 Directory Opus 当前路径
GetDopusPath() {
    oldClipboard := A_Clipboard
    A_Clipboard := ""
    newPath := ""
    RunWait(DopusrtPath ' /cmd Clipboard SET "`{sourcepath`}"', , "Hide")
    if ClipWait(0.2) {
        newPath := A_Clipboard
        A_Clipboard := oldClipboard
    }
    return newPath
}
; 获取 Explorer 当前路径
GetExplorerPath() {
    for window in ComObject("Shell.Application").Windows {
        try {
            if (InStr(window.FullName, "explorer.exe")) {
                return window.Document.Folder.Self.Path
            }
        }
    }
    return ""
}