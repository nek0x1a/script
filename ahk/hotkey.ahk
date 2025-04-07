#Requires AutoHotkey v2.0

; 路径
LocalAppData := EnvGet("LocalAppData")
Application := EnvGet("Application")

; 置顶当前窗口，再按一次解除
#t:: {
    WinSetAlwaysOnTop(-1, "A")
    ;对窗口置顶，-1 表示在on 与 off 中切换, "A" 表示当前窗口标题
    return
}
