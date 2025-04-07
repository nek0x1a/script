param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]$Path
)

if (!(Test-Path $Path -PathType Container)) {
    Write-Error "目标不是文件夹: $Path"
    exit 126
}

$Path = Convert-Path $Path
Write-Host "目标路径: " -NoNewline
Write-Host $Path -ForegroundColor Cyan

# 整理路径
$MoudleDir = Join-Path (Get-Item $PSCommandPath).Directory "../moudle" -Resolve

# 文件列表
$ChromeFiles = @(
    @{
        repository = 'Bush2021/chrome_plus'
        tag        = 'latest'
        pattern    = '^Chrome\+\+_v\d+\.\d+\.\d+.*.7z$'
    },
    @{
        repository = 'Bush2021/chrome_installer'
        tag        = 'latest'
        pattern    = '^x64_\d+\.\d+\.\d+\.\d+_chrome_installer.exe$'
    }
)

# 文件信息
$PrepareFiles = @{
    "ChromePlus"      = "Chrome++_*.7z";
    "ChromeInstaller" = "x64_*_chrome_installer.exe";
}
$Files = @{}

# 导入模块
Import-Module -Name (Join-Path $MoudleDir "Downloader") -Function Get-GithubAsset

# 获取文件
Write-Host "正在获取安装文件"
$WebClient = New-Object System.Net.WebClient

$ChromeFiles | ForEach-Object { 
    Get-GithubAsset  $_["repository"] $_["tag"] $_["pattern"] $WebClient
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
        Write-Host "准备以下文件:"
        $PrepareFiles.Keys | ForEach-Object { Write-Host "$($_): $($PrepareFiles[$_])" }
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

# 检查是否已安装
$Installed = @()
Get-ChildItem $Path | ForEach-Object {
    if ($_.Name -match 'chrome\.exe|chrome_proxy\.exe|\d+\.\d+\.\d+\.\d+|chrome\+\+\.ini|version\.dll') {
        $Installed += $_.Name
    }
}

if ($Installed.Count -gt 0) {
    Write-Host "已有 Chrome 在目标路径中"
    Read-Host -Prompt "Enter 进行升级..."
    $Installed | ForEach-Object {
        Join-Path $Path $_ | Remove-Item -Recurse -Force
    }
}
Write-Host $Files

Write-Host "解压 Chrome++..."
$TempPath = Join-Path $Path $Files['ChromePlus'].BaseName
7z x $Files['ChromePlus'].Name -o"$TempPath" -aoa
Join-Path $TempPath "x64/App" | Get-ChildItem | Move-Item -Destination $Path
Remove-Item $TempPath -Recurse -Force


Write-Host "解压 ChromeInstaller..."
$TempPath = Join-Path $Path "Chrome-bin"
7z x $Files['ChromeInstaller'] -o"$PWD" -aoa
7z x "chrome.7z" -o"$Path" -aoa
Get-ChildItem $TempPath | Move-Item -Destination $Path
Remove-Item "chrome.7z" -Force
Remove-Item $TempPath -Recurse -Force

Write-Host "安装完成"
