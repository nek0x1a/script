# 检查管理员权限
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 如果不是管理员角色则使用管理员身份重新运行脚本
    Start-Process "$($PSHOME)\pwsh.exe" -WorkingDirectory $PWD -Verb RunAs -ArgumentList "-file", $PSCommandPath, $PSBoundParameters
    return
}

# 初始化
$Host.UI.RawUI.WindowTitle = "Runtime 安装"

# 文件信息
$PrepareFiles = @{
    "WingetApps"    = "runtime.json";
    "DirectXRepair" = "DirectX_Repair_*.zip";
}
$Files = @{}

# 检测文件
:CheckFiles while ($true) {
    $Temp = $PrepareFiles.Keys | ForEach-Object {
        if (Test-Path $PrepareFiles[$_]) {
            Write-Host "$($PrepareFiles[$_]): " -NoNewline
            Write-Host "已找到" -ForegroundColor Green
            $Files[$_] = Get-Item $PrepareFiles[$_] | Select-Object -First 1
            $true
        }
        else {
            Write-Host "$($PrepareFiles[$_]): " -NoNewline
            Write-Host "未找到" -ForegroundColor Red
            $false
        }
    } | Where-Object { $_ }
    if ($Temp.Count -ne $PrepareFiles.Count) {
        Write-Host
        $Files.Clear()
        Read-Host -Prompt "Enter 重新检查..."
        continue CheckFiles
    }
    else {
        Read-Host -Prompt "Enter 进行安装..."
        Clear-Host
        break CheckFiles
    }
}

# 启用 .Net3.5
Enable-WindowsOptionalFeature -Online -FeatureName "NetFX3"  

# Winget 安装运行库
winget import -i $Files['WingetApps'] --accept-package-agreements --accept-source-agreements --disable-interactivity

# DirectX
Expand-Archive -Path $Files['DirectXRepair'] -DestinationPath $Files['DirectXRepair'].BaseName
$EntryPoint = Join-Path $Files['DirectXRepair'].BaseName "DirectX Repair.exe"
$EnterArgs = "/passive"
if (Test-Path $EntryPoint -PathType Leaf) {
    & $EntryPoint $EnterArgs
}

Write-Host "Runtime 安装完成"