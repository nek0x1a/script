# 检查管理员权限
$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if ( -not $CurrentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # 如果不是管理员角色则使用管理员身份重新运行脚本
    Start-Process "$($PSHOME)\pwsh.exe" -WorkingDirectory $PWD -Verb RunAs -ArgumentList "-file", $PSCommandPath, $PSBoundParameters
    return
}

# 初始化
$Host.UI.RawUI.WindowTitle = "Winget 安装"
# 整理路径
$MoudleDir = Join-Path (Get-Item $PSCommandPath).Directory "moudle" -Resolve

# 文件列表
$WingetFiles = @{
    winget = @{
        repository = 'microsoft/winget-cli'
        tag        = 'latest'
        pattern    = '.+_License1\.xml|^Microsoft\.DesktopAppInstaller_.+\.msixbundle$'
    }
    others = @(
        @{
            name = 'Microsoft.VCLibs.x64.14.00.Desktop.appx'
            url  = 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx'
        },
        @{
            name = 'microsoft.ui.xaml.2.8.7.nupkg'
            url  = 'https://www.nuget.org/api/v2/package/Microsoft.UI.Xaml/2.8.7'
        }
    )
}

# 文件信息
$PrepareFiles = @{
    "WingetLicense" = "*_License1.xml";
    "WingetPackage" = "Microsoft.DesktopAppInstaller_*.msixbundle";
    "VCLibs"        = "Microsoft.VCLibs.x64.*.Desktop.appx";
    "UIXaml"        = "microsoft.ui.xaml.*.nupkg";
}
$Files = @{}

# 导入模块
Import-Module -Name (Join-Path $MoudleDir "Downloader") -Function Get-GithubAsset

# 获取文件
Write-Host "正在获取安装文件"
$WebClient = New-Object System.Net.WebClient
Get-GithubAsset $WingetFiles["winget"]["repository"] $WingetFiles["winget"]["tag"] $WingetFiles["winget"]["pattern"] $WebClient
$WingetFiles.others | ForEach-Object {
    if (Test-Path $_.Name) {
        Write-Host "文件已存在: " -NoNewline
        Write-Host $_.Name -ForegroundColor Yellow
    }
    else {
        Write-Host "下载 " -NoNewline
        Write-Host $_.Name -ForegroundColor Cyan -NoNewline
        Write-Host "..."
        $WebClient.DownloadFile($_.Url, (Join-Path $PWD $_.Name))
    }
}

# 检测文件
:CheckFiles while ($true) {
    $PrepareFiles.Keys | ForEach-Object {
        if (Test-Path $PrepareFiles[$_]) {
            Write-Host "$($PrepareFiles[$_]): " -NoNewline
            Write-Host "已找到" -ForegroundColor Green
            $Files[$_] = Get-Item $PrepareFiles[$_] | Select-Object -First 1
        }
        else {
            Write-Host "$($PrepareFiles[$_]): " -NoNewline
            Write-Host "未找到" -ForegroundColor Red
        }
    }
    # 文件缺失
    if ($Files.Count -ne $PrepareFiles.Count) {
        $Files.Clear()
        Write-Host
        Write-Host "文件缺失，请重新运行脚本或手动准备文件；"
        Write-Host "官方教程: https://learn.microsoft.com/zh-cn/windows/iot/iot-enterprise/deployment/install-winget-windows-iot"
        Write-Host "准备以下文件:"
        $PrepareFiles.Keys | ForEach-Object {
            Write-Host "$($_): $($PrepareFiles[$_])"
        }
        Read-Host -Prompt "Enter 重新检查..."
        Clear-Host
        continue CheckFiles
    }
    else {
        Read-Host -Prompt "Enter 进行安装..."
        Clear-Host
        break CheckFiles
    }
}

# 安装
Write-Host "安装 Microsoft.VCLibs..."
Add-AppxPackage -Path $Files['VCLibs']

Write-Host "解压 Microsoft.UI.Xaml..."
Expand-Archive -Path $Files['UIXaml'] -DestinationPath $Files['UIXaml'].BaseName
$MicrosoftUIPackage = Join-Path $Files['UIXaml'].BaseName "tools" "AppX" "x64" "Release" | Get-ChildItem -Name | Where-Object {
    $_ -match '^Microsoft\.UI\.XAML\..+\.appx$'
} | Select-Object -First 1
Write-Host "安装 Microsoft.UI.Xaml..."
Add-AppxPackage -Path $MicrosoftUIPackage
Remove-Item $Files['UIXaml'].BaseName -Recurse

Write-Host "安装 Microsoft.Winget..."
Add-AppxPackage -Path $Files['WingetPackage']

Write-Host "签名 Microsoft.Winget..."
Add-AppxProvisionedPackage -Online -PackagePath $Files['WingetPackage'] -LicensePath $Files['WingetLicense']

# 完成
Write-Host "Microsoft.Winget 安装完成"
Read-Host -Prompt "Enter 退出"