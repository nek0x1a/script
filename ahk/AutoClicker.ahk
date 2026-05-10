#Requires AutoHotkey v2.0
#SingleInstance Force

; 全局变量
global SavedKey := "z" ; 默认按键
global SavedInterval := 200 ; 默认间隔 (毫秒)
global IsRunning := false ; 连击状态标记

; Ctrl + F10 - 设置窗口
^F10:: {
    ; 创建 GUI 对象
    SettingGui := Gui(, "连击设置")
    SettingGui.Opt("+AlwaysOnTop") ; 让窗口保持在最前
    SettingGui.SetFont("s10", "Microsoft YaHei")
    ; 按键
    SettingGui.Add("Text", "x20 y20 w60", "按键:")
    InputKeyObj := SettingGui.Add("ComboBox", "x90 y17 w100 vInputKey", ["z", "x", "a", "j", "LButton", "RButton"])
    InputKeyObj.Text := SavedKey
    ; 间隔
    SettingGui.Add("Text", "x20 y60 w60", "间隔(ms):")
    InputTimeObj := SettingGui.Add("Edit", "x90 y57 w100 Number vInputTime", SavedInterval)
    ; 动作
    SettingGui.Add("Button", "x40 y100 w70 Default", "确定").OnEvent("Click", SaveSettings)
    SettingGui.Add("Button", "x130 y100 w70", "取消").OnEvent("Click", (*) => SettingGui.Destroy())
    ; 显示界面
    SettingGui.Show()

    SaveSettings(*) {
        SavedObj := SettingGui.Submit() ; 获取控件内容并隐藏窗口
        ; 更新全局变量
        global SavedKey := SavedObj.InputKey = "" ? SavedKey : SavedObj.InputKey
        global SavedInterval := SavedObj.InputTime < 10 ? 200 : SavedInterval
        ; 提示
        ToolTip("✅ " SavedKey ": " SavedInterval)
        SetTimer(() => ToolTip(), -1000)
    }
}

; Ctrl + F11 - 开始/停止 自动按键
^F11:: {
    global IsRunning
    ; 没有设置按键则返回
    if (SavedKey == "") {
        return
    }
    if (IsRunning) {
        ; 停止
        SetTimer(DoClick, 0) ; 关闭定时器
        IsRunning := false
        ToolTip("❌ 已停止")
        SetTimer(() => ToolTip(), -1000)
    } else {
        ; 开始
        SetTimer(DoClick, SavedInterval) ; 启动定时器
        IsRunning := true
        ToolTip("✅ 自动按键 [" SavedKey "] " SavedInterval "ms")
        SetTimer(() => ToolTip(), -1000)
    }
}

DoClick() {
    ; 如果按键包含特殊字符（如 {Enter}），直接发送
    ; 如果是普通字符（如 z），也直接发送
    try {
        SendInput("{" SavedKey "}")
    } catch {
        ; 防止输入非法字符导致报错
        SendInput(SavedKey)
    }
}