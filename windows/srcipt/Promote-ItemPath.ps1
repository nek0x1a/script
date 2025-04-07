param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]$Path,
    [switch]$SubDirectories
)

if (!(Test-Path $Path -PathType Container)) {
    Write-Host "目标路径不是文件夹: " -NoNewline
    Write-Host $Path -ForegroundColor Yellow
    exit 126
}
$Path = Convert-Path $Path
Write-Host "目标路径: " -NoNewline
Write-Host $Path -ForegroundColor Cyan

function Promote {
    param (
        [Parameter(Mandatory = $true)]
        [String]$Path
    )
    # 找到 Path 下的文件夹
    Get-ChildItem $Path -Directory | ForEach-Object {
        # 文件夹下的所有内容移动到 Path
        $Files = Get-ChildItem $_ -Force
        Move-Item $Files $Path
        # 如果这个文件夹为空则删除
        if ($null -eq (Get-ChildItem $_ -File -Force -Recurse)) {
            Remove-Item $_ -Recurse
        }
    }
}

if ($SubDirectories) {
    # 对子文件夹应用
    Get-ChildItem $Path -Directory | ForEach-Object {
        Promote $_
    }
}
else {
    # 对本文件夹应用
    Promote $Path
}

Write-Host "操作完成"