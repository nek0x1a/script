param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]$Path,
    [switch]$WithParentName
)

if (!(Test-Path $Path -PathType Container)) {
    Write-Error "目标不是文件夹: $Path"
    exit 126
}

$Path = Convert-Path $Path
Write-Host "目标路径: " -NoNewline
Write-Host $Path -ForegroundColor Cyan

# 找到所有的文件
$Files = @()
Get-ChildItem $Path -Directory | ForEach-Object {
    $Files += Get-ChildItem $_ -File -Recurse -Force
}
if ($WithParentName) {
    $NewFiles = @()
    $Files | ForEach-Object {
        $NewName = $_.Directory.Name + "-" + $_.Name
        $NewFile = Rename-Item $_ $NewName -PassThru
        $NewFiles += $NewFile
    }
    $Files = $NewFiles
}
Move-Item $Files $Path

Write-Host "共移动 " -NoNewline
Write-Host $Files.Count -ForegroundColor Green -NoNewline
Write-Host " 个文件夹"
