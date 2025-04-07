param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String[]]$Path
)

if (!(Test-Path $Path -PathType Container)) {
    Write-Error "目标不是文件夹: $Path"
    exit 126
}

$Path = Convert-Path $Path
Write-Host "目标路径: " -NoNewline
Write-Host $Path -ForegroundColor Cyan

$DeletedCount = 0
$HasDeletedItem = $true
# 删除一次空文件夹后再次检查，直到没有空文件夹。
while ($HasDeletedItem) {
    $HasDeletedItem = $false
    Get-ChildItem $Path -Recurse -Directory | ForEach-Object {
        if ((Test-Path $_) -and ((Get-ChildItem $_ -Force) -eq $null)) {
            $HasDeletedItem = $true
            Remove-Item $_ -Recurse
            $DeletedCount += 1
        }
    }
    if ($HasDeletedItem) {
        Write-Debug "有删除项，重新搜索: $Path"

    }
}

Write-Host "共删除 " -NoNewline
Write-Host $DeletedCount -ForegroundColor Green -NoNewline
Write-Host " 个文件夹"
