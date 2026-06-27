param(
    [Parameter(Mandatory=$true)]
    [string]$InputPath,

    [ValidateRange(26,40)]
    [int]$Quality = 30,

    [ValidateSet('copy','low','high','none')]
    [string]$Audio = 'copy'
)

# 常见视频格式列表
$VideoExtensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.m2ts', '.3gp', '.3g2')

# 处理音频参数
$AudioParams = switch ($Audio) {
    'copy' { '-c:a copy' }
    'low'  { '-c:a aac -b:a 128k' }
    'high' { '-c:a aac -b:a 320k' }
    'none' { '-an' }
}

# 获取输入路径信息
$InputItem = Get-Item -LiteralPath $InputPath

if ($InputItem.PSIsContainer) {
    # 如果是目录，获取所有视频文件
    $GetParams = @{
        LiteralPath = $InputItem
        File = $true
    }
    $VideoFiles = Get-ChildItem @GetParams | Where-Object { $VideoExtensions -contains $_.Extension.ToLower() }
    
    if ($VideoFiles.Count -eq 0) {
        Write-Host "在目录中未找到任何视频文件" -ForegroundColor Yellow
        exit
    }
    
    Write-Host "找到 $($VideoFiles.Count) 个视频文件"
} else {
    # 如果是单个文件，检查是否为视频格式
    if ($VideoExtensions -notcontains $InputItem.Extension.ToLower()) {
        Write-Host "指定的文件不是视频: $($InputItem.Extension)" -ForegroundColor Yellow
        exit
    }
    $VideoFiles = @($InputItem)
}

# 统计变量
$Total = $VideoFiles.Count
$Success = 0
$Failed = 0

# 遍历并转换视频文件
foreach ($InputFile in $VideoFiles) {
    $OutputDir = $InputFile.DirectoryName
    $BaseName = $InputFile.BaseName
    $Extension = $InputFile.Extension
    
    # 构建输出文件名
    $OutputFile = Join-Path $OutputDir "$BaseName`_hevc$Extension"
    
    # 输出文件已存在，自动跳过
    if (Test-Path $OutputFile) {
        Write-Host "跳过已存在文件: $OutputFile" -ForegroundColor Yellow
        $Failed++
        continue
    }

    # 构建 FFmpeg 命令
    # ffmpeg -loglevel error -stats -hwaccel cuda -i "<input>" -c:v hevc_nvenc -cq 30  -c:a copy "<output>"
    $FfmpegCmd = @(
        'ffmpeg'
        '-loglevel error'
        '-stats'
        '-hwaccel cuda'
        '-i'
        "`"$($InputFile.FullName)`""
        '-c:v hevc_nvenc'
        "-cq $Quality"
        $AudioParams
        "`"$OutputFile`""
    ) -join ' '
    
    # 执行命令
    Invoke-Expression $FfmpegCmd
    
    # 检查执行结果
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  转换完成: $OutputFile" -ForegroundColor Green
        $Success++
    } else {
        Write-Host "  转换失败，错误码: $LASTEXITCODE" -ForegroundColor Red
        $Failed++
    }
}

# 输出汇总信息
Write-Host "`n总计: $Total, 成功: " -NoNewLine
Write-Host "$Success" -NoNewLine -ForegroundColor Green
Write-Host ", 失败: " -NoNewLine
Write-Host "$Failed" -NoNewLine -ForegroundColor Red