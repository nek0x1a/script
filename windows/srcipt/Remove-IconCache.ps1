[CmdletBinding()]
param(
    [switch]$Confirm
)

begin {
    $ShouldExecute = $true
    # 检查管理员权限
    $CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
    if (-not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        # 如果不是管理员角色则使用管理员身份重新运行脚本
        $CruuentArgs = @("-NoExit", "-file", "`"${PSCommandPath}`"")
        ${PSBoundParameters}.Keys | ForEach-Object {
            $Key = $_
            $Value = ${PSBoundParameters}[$Key]
            $CruuentArgs += "-$Key"
            if (($Value -isnot [switch]) -and ($Value -isnot [bool])) {
                $CruuentArgs += "$Value"
            }
        }
        Start-Process "pwsh.exe" -Verb RunAs -ArgumentList $CruuentArgs
        $ShouldExecute = $false
    }
}

process {
    if (-not $ShouldExecute) {
        return
    }
    
    if (-not $Confirm) {
        $ConfirmString = Read-Host "将重启资源管理器 $($PSStyle.Underline)Y$($PSStyle.UnderlineOff)es / $($PSStyle.Underline)N$($PSStyle.UnderlineOff)o"
        if (-not ($ConfirmString.ToLower() -match '^y$|^yes$')) {
            return
        }
    }

    $ShellRestartReg = @{
        Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
        Name = "AutoRestartShell"
    }
    $ShellRestartValue = Get-ItemPropertyValue @ShellRestartReg
    Set-ItemProperty @ShellRestartReg -Value 0
    Stop-Process -Name explorer -Force

    $IconCachePath = "${env:LOCALAPPDATA}\iconCache.db"
    $ThumbCachePath = "${env:LOCALAPPDATA}\Microsoft\Windows\Explorer\thumbcache_*.db"
    if (Test-Path $IconCachePath) {
        Remove-Item $IconCachePath -Force
    }
    if (Test-Path $ThumbCachePath) {
        Remove-Item $ThumbCachePath -Force -Recurse
    }

    $TrayReg = @(
        @{
            Path = "Registry::HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
            Name = "IconStreams"
        }
        @{
            Path = "Registry::HKEY_CLASSES_ROOT\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify"
            Name = "PastIconsStream"
        }
    )
    $TrayReg | ForEach-Object {
        $CurrentReg = $_
        if (Get-ItemProperty @CurrentReg -ErrorAction SilentlyContinue) {
            Remove-ItemProperty @CurrentReg
        }
    }

    Set-ItemProperty @ShellRestartReg -Value $ShellRestartValue
    Start-Process explorer
}