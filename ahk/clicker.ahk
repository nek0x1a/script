#Requires AutoHotkey v2.0
; F11: 终止连点并显示菜单
; F10: 根据菜单设置启动连点

class Clicker {
    ; 启用连点器标志
    IsActivated := false
    ; 当按下启动键时才连点
    Press := false
    ; 睡眠时间
    Sleep := 300
    ; 选择选择的按键
    ActivatedKey := ""
    ; 选择菜单
    ; 在此处定义按键
    Keys := Map("鼠标左键", {
        ; 按键，支持单个字母和 'click'
        key: "click",
        ; 被选择
        selected: false
    })

    ; 生成菜单回调函数
    GetMenuCB() {
        InnerMenuClickCB(itemName, itemPos, thisMenu) {
            ; 重新设置选择按键
            this.ActivatedKey := ""
            ; 取消所有选择
            for k, v in this.Keys {
                thisMenu.Uncheck(k)
                v.selected := false
            }
            if itemName == "保持按住" {
                ; 切换按键模式
                this.press := !this.press
                thisMenu.ToggleCheck(itemName)
            } else {
                ; 选择按键
                thisMenu.Check(itemName)
                this.ActivatedKey := this.Keys[itemName].key
                this.Keys[itemName].selected := true
            }
        }
        return InnerMenuClickCB
    }

    ; 设置间隔时间
    SetSleep(Millisecond) {
        this.Sleep := Millisecond
    }

    ; 设置按键
    SetKey(Name, Key) {
        ; 检查按键是否合法
        if RegExMatch(Key, "^([a-z]|[A-Z]|Numpad(\d|Dot|Div|Mult|Add|Sub)|Space)$") {
            this.Keys.Set(Name, {
                Key: Key,
                selected: false,
            })
        } else {
            throw ValueError("指定的按键不合法")
        }
    }

    ; 根据配置的按键生成菜单
    SetMenu() {
        this.Menu := Menu()
        ; 添加按键列表
        for k, v in this.Keys {
            this.Menu.Add(k, this.GetMenuCB())
        }
        this.Menu.Add("保持按住", this.GetMenuCB())
    }

    ; 展示菜单
    ShowMenu() {
        this.Menu.Show()
    }

    ; 启用连点
    Activate() {
        this.IsActivated := true
    }

    ; 停止连点
    Deactivate() {
        this.IsActivated := false
    }
}

; 生成并配置连点器
AppClicker := Clicker()
AppClicker.SetKey("按键 Z", "z")
AppClicker.SetMenu()

; 选择菜单
F11:: {
    ; 取消连点
    AppClicker.Deactivate()
    ; 显示菜单
    AppClicker.ShowMenu()
}

; 启动按键
$F10:: {
    ; 当需要保持按住时的按键，默认与启动按键一致
    StartKey := "F10"
    ; 激活连点标志
    AppClicker.Activate()
    switch AppClicker.ActivatedKey {
        case "click":
            {
                ; 为鼠标点击时
                if AppClicker.Press {
                    while GetKeyState(StartKey, "P") {
                        Click "Left"
                        Sleep AppClicker.Sleep
                    }
                } else {
                    while AppClicker.IsActivated {
                        Click "Left"
                        Sleep AppClicker.Sleep
                    }
                }
            }
        default:
        {
            ; 为有效按键时
            if AppClicker.Press {
                while GetKeyState(StartKey, "P") {
                    Send "{" AppClicker.ActivatedKey "}"
                    Sleep AppClicker.Sleep
                }
            } else {
                while AppClicker.IsActivated {
                    Send "{" AppClicker.ActivatedKey "}"
                    Sleep AppClicker.Sleep
                }
            }
        }
    }
}
