# 检查管理员权限
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 如果不是管理员角色则使用管理员身份重新运行脚本
    Start-Process "$($PSHOME)\pwsh.exe" -Verb RunAs -ArgumentList "-file", $PSCommandPath, $PSBoundParameters
    return
}

# 初始化
$Host.UI.RawUI.WindowTitle = "Windows 配置"
# 整理路径
$WorkDir = Split-Path -Parent $PSCommandPath
Push-Location $WorkDir

# 类型
enum OptionalSwitch {
    on = 1
    off = 0
    keep = -1
}

# 配置
$ConfigMap = @{
    # 配置文件
    # 除特殊注明外，接受选项: "on", "off", "keep"
    # 分别表示: 启用、警用、保持现有设置不改动
    "Desktop"  = @{
        # 接受选项: "10", "11", "keep"
        "ContextMenuStyle"    = "10";
        "ShowIconThispc"      = "keep";
        "ShowIconProfile"     = "keep";
        "ShowIconRecycle"     = "off";
        "ShowIconControl"     = "keep";
        "ShowIconNetwork"     = "keep";
        "ShowTaskbarTaskview" = "off";
        "ShowTaskbarNews"     = "keep";
        # 接受选项: 0, 1, 2， -1
        # 分别表示: 隐藏、图标、搜索框、保持现有设置不改动
        "TaskbarSearchMode"   = 0;

    };
    "Explorer" = @{
        # 接受选项: "pc", "home", "keep"
        # 分别表示: 此电脑、主文件夹、保持现有设置不改动
        "Startpage"            = "pc";
        "ShowFolder"           = "keep";
        "ShowFiletreeGallery"  = "keep";
        "ShowFiletreePortable" = "off";
        "ShowFileExt"          = "on";
        "ShowNormalHiddenfile" = "on";
        "ShowSystemHiddenfile" = "off";
    };
    "System"   = @{
        # 接受选项: "<任意字符串>", ""
        # 分别表示: 设置 NTP 服务器为<任意字符串>、保持现有设置不改动
        "NtpServer"           = "openwrt.meow";
        "EnableGamedvr"       = "off";
        "EnableHibernate"     = "off";
        "EnableUpdateEdge"    = "keep";
        "EnableUpdateWindows" = "keep";
    };
}

class DesktopConfig {
    [ValidateSet("10", "11", "keep")]
    [String]$ContextMenuStyle
    [OptionalSwitch]$ShowIconThispc
    [OptionalSwitch]$ShowIconProfile
    [OptionalSwitch]$ShowIconRecycle = [OptionalSwitch]::keep
    [OptionalSwitch]$ShowIconControl
    [OptionalSwitch]$ShowIconNetwork
    [OptionalSwitch]$ShowTaskbarTaskview
    [OptionalSwitch]$ShowTaskbarNews
    [ValidateSet(0, 1, 2, -1)]
    [int]$TaskbarSearchMode
    DesktopConfig() { $this.Init(@{}) }
    DesktopConfig([hashtable]$Properties) { $this.Init($Properties) }
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }
    [void] Show() {
        Write-Host "[桌面]"
        if ($this.ContextMenuStyle -ne "keep") {
            Write-Host "右键菜单样式: " -NoNewline
            Write-Host "Windows $($this.ContextMenuStyle)" -ForegroundColor Green
        }
        if ($this.ShowIconThispc -ne [OptionalSwitch]::keep) {
            Write-Host "桌面图标-此电脑: " -NoNewline
            if ($this.ShowIconThispc -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowIconProfile -ne [OptionalSwitch]::keep) {
            Write-Host "桌面图标-用户文件夹: " -NoNewline
            if ($this.ShowIconProfile -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowIconRecycle -ne [OptionalSwitch]::keep) {
            Write-Host "桌面图标-回收站: " -NoNewline
            if ($this.ShowIconRecycle -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowIconControl -ne [OptionalSwitch]::keep) {
            Write-Host "桌面图标-控制面板: " -NoNewline
            if ($this.ShowIconControl -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowIconNetwork -ne [OptionalSwitch]::keep) {
            Write-Host "桌面图标-网络: " -NoNewline
            if ($this.ShowIconNetwork -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }

        if ($this.ShowTaskbarTaskview -ne [OptionalSwitch]::keep) {
            Write-Host "任务栏-任务按钮: " -NoNewline
            if ($this.ShowTaskbarTaskview -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowTaskbarNews -ne [OptionalSwitch]::keep) {
            Write-Host "任务栏-小组件: " -NoNewline
            if ($this.ShowTaskbarNews -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.TaskbarSearchMode -ne -1) {
            Write-Host "任务栏-搜索按钮样式: " -NoNewline
            switch ($this.TaskbarSearchMode) {
                0 { Write-Host  "隐藏" -ForegroundColor Green }
                1 { Write-Host  "按钮" -ForegroundColor Green }
                2 { Write-Host  "搜索框" -ForegroundColor Green }
                Default {}
            }
        }
    }
}
class ExplorerConfig {
    [ValidateSet("pc", "home", "keep")]
    [String]$Startpage
    [OptionalSwitch]$ShowFolder
    [OptionalSwitch]$ShowFiletreeGallery
    [OptionalSwitch]$ShowFiletreePortable
    [OptionalSwitch]$ShowFileExt
    [OptionalSwitch]$ShowNormalHiddenfile
    [OptionalSwitch]$ShowSystemHiddenfile
    DesktopConfig() { $this.Init(@{}) }
    DesktopConfig([hashtable]$Properties) { $this.Init($Properties) }
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }
    [void] Show() {
        Write-Host "[资源管理器]"
        if ($this.Startpage -ne "keep") {
            Write-Host "资源管理器-起始页面: " -NoNewline
            switch ($this.Startpage) {
                "pc" { Write-Host  "此电脑" -ForegroundColor Green }
                "home" { Write-Host  "主文件夹" -ForegroundColor Green }
                Default {}
            }
        }
        if ($this.ShowFolder -ne [OptionalSwitch]::keep) {
            Write-Host "资源管理器-文件夹图标: " -NoNewline
            if ($this.ShowFolder -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowFiletreeGallery -ne [OptionalSwitch]::keep) {
            Write-Host "文件树-图库图标: " -NoNewline
            if ($this.ShowFiletreeGallery -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowFiletreePortable -ne [OptionalSwitch]::keep) {
            Write-Host "文件树-便携磁盘图标: " -NoNewline
            if ($this.ShowFiletreePortable -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowFileExt -ne [OptionalSwitch]::keep) {
            Write-Host "资源管理器-文件扩展名: " -NoNewline
            if ($this.ShowFileExt -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowNormalHiddenfile -ne [OptionalSwitch]::keep) {
            Write-Host "资源管理器-普通隐藏文件: " -NoNewline
            if ($this.ShowNormalHiddenfile -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
        if ($this.ShowSystemHiddenfile -ne [OptionalSwitch]::keep) {
            Write-Host "资源管理器-系统隐藏文件: " -NoNewline
            if ($this.ShowSystemHiddenfile -eq [OptionalSwitch]::on) {
                Write-Host "显示" -ForegroundColor Green
            }
            else { Write-Host "隐藏" -ForegroundColor Yellow }
        }
    }
}
class SystemConfig {
    [String]$NtpServer
    [OptionalSwitch]$EnableGamedvr
    [OptionalSwitch]$EnableHibernate
    [OptionalSwitch]$EnableUpdateEdge
    [OptionalSwitch]$EnableUpdateWindows
    DesktopConfig() { $this.Init(@{}) }
    DesktopConfig([hashtable]$Properties) { $this.Init($Properties) }
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }
    [void] Show() {
        Write-Host "[系统]"
        if ($this.NtpServer -ne "") {
            Write-Host "系统-事件同步服务器: " -NoNewline
            Write-Host $this.NtpServer -ForegroundColor Green
        }
        if ($this.EnableGamedvr -ne [OptionalSwitch]::keep) {
            Write-Host "系统-游戏覆盖层: " -NoNewline
            if ($this.EnableGamedvr -eq [OptionalSwitch]::on) {
                Write-Host "启用" -ForegroundColor Green
            }
            else { Write-Host "禁用" -ForegroundColor Yellow }
        }
        if ($this.EnableHibernate -ne [OptionalSwitch]::keep) {
            Write-Host "系统-休眠: " -NoNewline
            if ($this.EnableHibernate -eq [OptionalSwitch]::on) {
                Write-Host "启用" -ForegroundColor Green
            }
            else { Write-Host "禁用" -ForegroundColor Yellow }
        }
        if ($this.EnableUpdateEdge -ne [OptionalSwitch]::keep) {
            Write-Host "更新-Edge: " -NoNewline
            if ($this.EnableUpdateEdge -eq [OptionalSwitch]::on) {
                Write-Host "启用" -ForegroundColor Green
            }
            else { Write-Host "禁用" -ForegroundColor Yellow }
        }
        if ($this.EnableUpdateWindows -ne [OptionalSwitch]::keep) {
            Write-Host "更新-Windows: " -NoNewline
            if ($this.EnableUpdateWindows -eq [OptionalSwitch]::on) {
                Write-Host "启用" -ForegroundColor Green
            }
            else { Write-Host "禁用" -ForegroundColor Yellow }
        }
    }
}
class Optimizer {
    [DesktopConfig]$Desktop
    [ExplorerConfig]$Explorer
    [SystemConfig]$System
    Optimizer() { $this.Init(@{}) }
    Optimizer([hashtable]$Properties) { $this.Init($Properties) }
    [void] Init([hashtable]$Properties) {
        foreach ($Property in $Properties.Keys) {
            $this.$Property = $Properties.$Property
        }
    }
    [void] ShowConfig() {
        Write-Host "本配置将修改以下设置:"
        $this.Desktop.Show()
        $this.Explorer.Show()
        $this.System.Show()
    }
    [void] ApplyDesktop() {
        if ($this.Desktop.ContextMenuStyle -ne "keep") {
            $RegPath = "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}"
            switch ($this.Desktop.ContextMenuStyle) {
                "10" {
                    if (!(Test-Path $RegPath)) {
                        New-Item (Join-Path $RegPath "InprocServer32") -Value "" -Force
                    }
                }
                "11" {
                    if (Test-Path $RegPath) {
                        Remove-Item $RegPath -Recurse
                    }
                }
                Default {}
            }
        }
        $IconRegPath = "Registry::HKEY_LOCAL_MACHINE\Software\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel"
        $IconRegUUID = @{
            "Thispc"  = "{20D04FE0-3AEA-1069-A2D8-08002B30309D}"
            "Profile" = "{59031a47-3f72-44a7-89c5-5595fe6b30ee}"
            "Recycle" = "{645FF040-5081-101B-9F08-00AA002F954E}"
            "Control" = "{5399E694-6CE5-4D6C-8FCE-1D8870FDCBA0}"
            "Network" = "{F02C1A0D-BE21-4350-88B0-7367FC96EF3C}"
        }
        if ($this.Desktop.ShowIconThispc -ne [OptionalSwitch]::keep) {
            if ($this.Desktop.ShowIconThispc -eq [OptionalSwitch]::on) { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Thispc"] -Value 0 }
            else { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Thispc"] -Value 1 }
        }
        if ($this.Desktop.ShowIconProfile -ne [OptionalSwitch]::keep) {
            if ($this.Desktop.ShowIconProfile -eq [OptionalSwitch]::on) { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Profile"] -Value 0 }
            else { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Profile"] -Value 1 }
        }
        if ($this.Desktop.ShowIconRecycle -ne [OptionalSwitch]::keep) {
            if ($this.Desktop.ShowIconRecycle -eq [OptionalSwitch]::on) { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Recycle"] -Value 0 }
            else { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Recycle"] -Value 1 }
        }
        if ($this.Desktop.ShowIconControl -ne [OptionalSwitch]::keep) {
            if ($this.Desktop.ShowIconControl -eq [OptionalSwitch]::on) { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Control"] -Value 0 }
            else { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Control"] -Value 1 }
        }
        if ($this.Desktop.ShowIconNetwork -ne [OptionalSwitch]::keep) {
            if ($this.Desktop.ShowIconNetwork -eq [OptionalSwitch]::on) { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Network"] -Value 0 }
            else { Set-ItemProperty $IconRegPath -Name $IconRegUUID["Network"] -Value 1 }
        }

        $TaskbarRegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
        if ($this.Desktop.ShowTaskbarTaskview -ne [OptionalSwitch]::keep) {
            Write-Host "任务栏-任务视图按钮: " -NoNewline
            if ($this.Desktop.ShowTaskbarTaskview -eq [OptionalSwitch]::on) { Set-ItemProperty $TaskbarRegPath -Name "ShowTaskViewButton" -Value 1 }
            else { Set-ItemProperty $TaskbarRegPath -Name "ShowTaskViewButton" -Value 0 }
        }
        if ($this.Desktop.ShowTaskbarNews -ne [OptionalSwitch]::keep) {
            if ($this.Desktop.ShowTaskbarNews -eq [OptionalSwitch]::on) { Set-ItemProperty $TaskbarRegPath -Name "TaskbarDa" -Value 1 }
            else { Set-ItemProperty $TaskbarRegPath -Name "TaskbarDa" -Value 0 }
        }
        if ($this.Desktop.TaskbarSearchMode -ne -1) {
            $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search"
            Set-ItemProperty $RegPath -Name "SearchboxTaskbarMode" -Value $this.Desktop.TaskbarSearchMode
        }
    }
    [void] ApplyExplorer() {
        if ($this.Explorer.Startpage -ne "keep") {
            $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            switch ($this.Explorer.Startpage) {
                "pc" { Set-ItemProperty $RegPath -Name "LaunchTo" -Value 1 }
                "home" { Set-ItemProperty $RegPath -Name "LaunchTo" -Value 2 }
                Default {}
            }
        }
        if ($this.Explorer.ShowFolder -ne [OptionalSwitch]::keep) {
            $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace"
            $NameSpaces = @(
                "{f86fa3ab-70d2-4fc7-9c99-fcbf05467f3a}",
                "{d3162b92-9365-467a-956b-92703aca08af}",
                "{B4BFCC3A-DB2C-424C-B029-7FE99A87C641}",
                "{3dfdf296-dbec-4fb4-81d1-6a3438bcf4de}",
                "{088e3905-0323-4b02-9826-5d99428e115f}",
                "{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}",
                "{24ad3ad4-a569-4530-98e1-ab02f9417aa8}"
            )
            if ($this.Explorer.ShowFolder -eq [OptionalSwitch]::on) {
                $NameSpaces | ForEach-Object {
                    $ItemPath = Join-Path $RegPath $_
                    if (-not (Test-Path $ItemPath)) {
                        New-Item $ItemPath
                    }
                }
            }
            else {
                $NameSpaces | ForEach-Object {
                    $ItemPath = Join-Path $RegPath $_
                    if (Test-Path $ItemPath) {
                        Remove-Item $ItemPath
                    }
                }
            }
        }
        if ($this.Explorer.ShowFiletreeGallery -ne [OptionalSwitch]::keep) {
            $RegPath1 = "HKCU:\Software\Classes\CLSID\"
            $RegPath2 = "Registry::HKEY_CLASSES_ROOT\CLSID\"
            $NameSpace = "{e88865ea-0e1c-4e20-9aa6-edcd0212c87c}"
            $ItemKey = "System.IsPinnedToNameSpaceTree"
            $MainPath = Join-Path $RegPath1 $NameSpace
            $RootPath = Join-Path $RegPath2 $NameSpace
            if (!(Test-Path $MainPath)) { Copy-Item $RootPath $MainPath }
            if ($this.Explorer.ShowFiletreeGallery -eq [OptionalSwitch]::on) {
                Set-ItemProperty $MainPath -Name $ItemKey -Value 1
                Set-ItemProperty $RootPath -Name $ItemKey -Value 1
            }
            else {
                Set-ItemProperty $MainPath -Name $ItemKey -Value 0
                Set-ItemProperty $RootPath -Name $ItemKey -Value 0
            }
        }
        if ($this.Explorer.ShowFiletreePortable -ne [OptionalSwitch]::keep) {
            $RegPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\DelegateFolders\{F5FB2C77-0E2F-4A16-A381-3E560C68BC83}"
            if ($this.Explorer.ShowFiletreePortable -eq [OptionalSwitch]::on) {
                New-Item $RegPath -Value "Removable Drives" -Force
            }
            else { Remove-Item $RegPath }
        }
        if ($this.Explorer.ShowFileExt -ne [OptionalSwitch]::keep) {
            $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if ($this.Explorer.ShowFileExt -eq [OptionalSwitch]::on) { Set-ItemProperty $RegPath -Name "HideFileExt" -Value 0 }
            else { Set-ItemProperty $RegPath -Name "HideFileExt" -Value 1 }
        }
        if ($this.Explorer.ShowNormalHiddenfile -ne [OptionalSwitch]::keep) {
            $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if ($this.Explorer.ShowNormalHiddenfile -eq [OptionalSwitch]::on) {
                Set-ItemProperty $RegPath -Name "Hidden" -Value 1
                Set-ItemProperty $RegPath -Name "ShowSuperHidden" -Value 0
            }
            else {
                Set-ItemProperty $RegPath -Name "Hidden" -Value 2
                Set-ItemProperty $RegPath -Name "ShowSuperHidden" -Value 0
            }
        }
        if ($this.Explorer.ShowSystemHiddenfile -ne [OptionalSwitch]::keep) {
            $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
            if ($this.Explorer.ShowSystemHiddenfile -eq [OptionalSwitch]::on) {
                Set-ItemProperty $RegPath -Name "Hidden" -Value 1
                Set-ItemProperty $RegPath -Name "ShowSuperHidden" -Value 1
            }
            else {
                Set-ItemProperty $RegPath -Name "Hidden" -Value 1
                Set-ItemProperty $RegPath -Name "ShowSuperHidden" -Value 0
            }
        }
    }
    [void] ApplySystem() {
        if ($this.System.NtpServer -ne "") {
            $RegPath1 = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DateTime\Servers\"
            $RegPath2 = "HKLM:\SYSTEM\CurrentControlSet\services\W32Time\Parameters"
            Set-ItemProperty $RegPath1 -Name "(Default)" -Value 0
            Set-ItemProperty $RegPath1 -Name 0 -Value $this.System.NtpServer
            Set-ItemProperty $RegPath2 -Name "NtpServer" -Value $this.System.NtpServer
            Restart-Service W32Time
        }
        if ($this.System.EnableGamedvr -ne [OptionalSwitch]::keep) {
            $RegPaths = @(
                @{
                    path = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR"
                    Key  = "AppCaptureEnabled"
                },
                @{
                    path = "HKCU:\System\GameConfigStore"
                    key  = "GameDVR_Enabled"
                }
            )
            if ($this.System.EnableGamedvr -eq [OptionalSwitch]::on) {
                $RegPaths | ForEach-Object {
                    Set-ItemProperty -Path $_.path -Name $_.key -Value 1
                }
            }
            else {
                $RegPaths | ForEach-Object {
                    Set-ItemProperty -Path $_.path -Name $_.key -Value 0
                }
            }
        }
        if ($this.System.EnableHibernate -ne [OptionalSwitch]::keep) {
            if ($this.System.EnableHibernate -eq [OptionalSwitch]::on) { powercfg /hibernate on }
            else { powercfg /hibernate off }
        }
        if ($this.System.EnableUpdateEdge -ne [OptionalSwitch]::keep) {
            if ($this.System.EnableUpdateEdge -eq [OptionalSwitch]::on) {
                Set-Service -Name "edgeupdate" -StartupType Manual
                Set-Service -Name "edgeupdatem" -StartupType Manual
                Set-Service -Name "MicrosoftEdgeElevationService" -StartupType Manual
                schtasks /query /fo csv > tasks.csv
                Import-Csv tasks.csv -Header "name", "time", "mode" -Encoding ansi | where-Object {
                    $_.name -match '^\\MicrosoftEdgeUpdate.+'
                } | ForEach-Object {
                    schtasks /change /tn $_.name /enable
                }
                Remove-Item tasks.csv
            }
            else {
                if ((Get-Process | Where-Object { $_.ProcessName -eq "msedge" }).Count -ne 0) {
                    Stop-Process -Name "msedge" -Force
                }
                if ((Get-Process | Where-Object { $_.ProcessName -eq "MicrosoftEdgeUpdate" }).Count -ne 0) {
                    Stop-Process -Name "MicrosoftEdgeUpdate" -Force
                }
                Get-Service | Where-Object {
                    $_.Name -match "edgeupdate|edgeupdatem|MicrosoftEdgeElevationService"
                } | ForEach-Object {
                    Set-Service -Name $_.Name -StartupType Disabled
                    if ($_.Status -eq "Running") { Stop-Service -Name $_.Name }
                }
                schtasks /query /fo csv > tasks.csv
                Import-Csv tasks.csv -Header "name", "time", "mode" -Encoding ansi | where-Object {
                    $_.name -match '^\\MicrosoftEdgeUpdate.+'
                } | ForEach-Object {
                    schtasks /change /tn $_.name /disable
                }
                Remove-Item tasks.csv
            }
        }
        if ($this.System.EnableUpdateWindows -ne [OptionalSwitch]::keep) {
            $RegPath1 = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
            $RegPath2 = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings"
            if ($this.System.EnableUpdateWindows -eq [OptionalSwitch]::on) {
                Remove-ItemProperty $RegPath2 -Name "FlightSettingsMaxPauseDays"
                if (Test-Path $RegPath1) {
                    Remove-Item $RegPath1 -Recurse
                }
            }
            else {
                Set-ItemProperty $RegPath2 -Name "FlightSettingsMaxPauseDays" -Value 365
                $RegPath1 = Join-Path $RegPath1 "AU"
                if (!(Test-Path $RegPath1)) {
                    New-Item $RegPath1 -Force
                }
                Set-ItemProperty $RegPath1 -Name "NoAutoUpdate" -Value 1
            }
        }
    }
    [void] Apply() {
        $this.ApplyDesktop()
        $this.ApplyExplorer()
        $this.ApplySystem()
    }
}

$WindowsOptimizer = [Optimizer]::new($ConfigMap)

# 展示选项
# 格式: [ FeatureKey ] FeatureName
function Show-FeatureItem {
    param (
        [Parameter(Mandatory = $true)]
        [string]$FeatureKey,
        [System.ConsoleColor]$ForegroundColor,
        [Parameter(Mandatory = $true)]
        [string]$FeatureName
    )
    Write-Host "[ " -NoNewline
    Write-Host $FeatureKey -ForegroundColor $ForegroundColor -NoNewline
    Write-Host " ] " -NoNewline
    Write-Host $FeatureName
}

function Restart-Explorer {
    Stop-Process -Name "explorer" -Force
    Start-Sleep -Seconds 5
    if ((Get-Process | Where-Object { $_.ProcessName -eq "explorer" }).Count -eq 0) {
        Start-Process -FilePath "explorer"
    }
}


# 主菜单
while ($true) {
    Write-Host "====== Optimize-Windows ======" -ForegroundColor White -BackgroundColor Blue
    Write-Host

    # 显示配置
    $WindowsOptimizer.ShowConfig()

    # 展示选项
    Write-Host
    Show-FeatureItem -FeatureKey "Proceed" -FeatureName "执行配置" -ForegroundColor Cyan
    Show-FeatureItem -FeatureKey "Quit" -FeatureName "退出" -ForegroundColor Gray
    Write-Host
    $Selection = Read-Host -Prompt "选择操作"

    Switch -Regex ($Selection.ToUpper()) {
        '^(?:P|PROCEED)$' {
            # 执行配置


            Write-Host
            Write-Host "脚本执行完毕"
            Read-Host -Prompt "Enter 退出"
            exit 0
        }
        default {
            Write-Host "退出脚本"
            exit 0
        }
    }
}