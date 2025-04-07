param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]$Source,
    [Parameter(Mandatory = $true)]
    [String]$Target,
    [switch]$Delete
)

# 自定义变量
$IncludeFiles = '*.bmp', '*.jpg', '*.jpeg', '*.png', '*.gif', '*.webp', '*.avif', '*.apng'

# 处理路径
if (!(Test-Path -Path $Source -PathType Container)) {
    Write-Host "源路径不是文件夹: " -NoNewline
    Write-Host $Source -ForegroundColor Yellow
    exit 126
}
if (!(Test-Path -Path $Target -PathType Container)) {
    Write-Host "目标路径不是文件夹: " -NoNewline
    Write-Host $Target -ForegroundColor Yellow
    exit 126
}

$Target = Join-Path $Target -ChildPath (Get-Date -Format "yyyyMMdd")

if (!(Test-Path $Target)) {
    New-Item $Target -ItemType Directory
}
if (!(Test-Path -Path $Target -PathType Container)) {
    Write-Host "目标路径不是文件夹: " -NoNewline
    Write-Host $Target -ForegroundColor Yellow
    exit 126
}

$Source = Convert-Path $Source
$Target = Convert-Path $Target
Write-Host "源路径: " -NoNewline
Write-Host $Source -ForegroundColor Cyan
Write-Host "目标路径: " -NoNewline
Write-Host $Target -ForegroundColor Cyan

# 查找文件并压缩
Get-ChildItem $Source -Directory | ForEach-Object {
    $PackageFullName = $_.Name + ".zip"
    $PackageFiles = Get-ChildItem $_ -Recurse -File -Include $IncludeFiles
    Write-Host "正在创建: " -NoNewline
    $PackagePath = Join-Path $Target $PackageFullName
    Write-Host $PackageFullName -ForegroundColor Green -NoNewline
    Write-Host "..."
    7z a -mx0 $PackagePath $PackageFiles
    if ($Delete) {
        Remove-Item $_ -Recurse -Force
    }
}

