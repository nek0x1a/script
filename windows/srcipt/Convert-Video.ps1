param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [String]$Source,
    [Parameter(Mandatory = $true)]
    [String]$Target,
    [switch]$Delete
)

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

$Source = Convert-Path $Source
$Target = Convert-Path $Target
Write-Host "源路径: " -NoNewline
Write-Host $Source -ForegroundColor Cyan
Write-Host "目标路径: " -NoNewline
Write-Host $Target -ForegroundColor Cyan

Get-ChildItem $Source -File | ForEach-Object {
    Write-Host "正在转换: " -NoNewline
    Write-Host $_.Name -ForegroundColor Cyan -NoNewline
    Write-Host "..."
    $SourceFile = Join-Path $Source $_.Name
    $TargetFile = Join-Path $Target "Convert_$($_.BaseName).mp4"
    # 去除音频
    # ffmpeg.exe -i "$($SourceFile)" -an -c:v h264_nvenc -preset slow -crf 28 "$($TargetFile)"
    # 拷贝音频
    ffmpeg.exe -i "$($SourceFile)" -c:a copy -c:v h264_nvenc -preset slow -crf 28 "$($TargetFile)"
    # 处理音频
    # ffmpeg.exe -i "$($SourceFile)" -acodec aac -b:a 128k -c:v h264_nvenc -preset slow -crf 28 "$($TargetFile)"
}

Write-Host "转换完成"