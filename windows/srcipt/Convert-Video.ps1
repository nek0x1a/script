<#
.SYNOPSIS
    使用HEVC编码和硬件加速转换视频文件

.DESCRIPTION
    批量转换视频文件为HEVC格式（H.265），使用NVIDIA硬件加速。支持以下功能：
    - 单个文件或整个目录的批量转换
    - 自定义质量等级和音频编码方式
    - 自动跳过已存在的输出文件
    - 详细的处理统计和错误报告

.PARAMETER Source
    视频文件路径或包含视频文件的目录。支持的格式：mp4, mkv, avi, mov, wmv, flv, webm, m4v, mpg, mpeg, ts, m2ts, 3gp, 3g2

.PARAMETER Destination
    视频文件输出目录。如果未指定，则默认与输入路径相同。

.PARAMETER Quality
    HEVC编码质量等级，取值范围26-40。数值越小质量越高、文件越大。默认值30提供良好的质量和压缩比平衡。

.PARAMETER Audio
    音频编码方式。可选值：
    - 'copy': 复制原始音频轨道（默认，无重新编码）
    - 'low': 低质量AAC编码（128k）
    - 'high': 高质量AAC编码（320k）
    - 'none': 移除音频轨道

.EXAMPLE
    # 转换单个视频文件，使用默认质量和音频复制
    .\Convert-Video.ps1 "C:\Videos\movie.mp4"

.EXAMPLE
    # 转换整个目录的视频，使用自定义质量
    .\Convert-Video.ps1 "C:\Videos" -Quality 28 -Audio low

.EXAMPLE
    # 转换并使用高质量音频编码
    .\Convert-Video.ps1 "C:\Videos\movie.mkv" -Audio high

.NOTES
    依赖项：
    - FFmpeg（需在系统PATH中或可直接调用）
    - NVIDIA GPU和驱动程序（支持CUDA硬件加速）
    
    输出文件：
    - 转换后的文件保存在源文件所在目录
    - 输出文件名格式：{原名}_hevc{原扩展名}
    - 已存在的输出文件将被自动跳过

    性能说明：
    - 使用NVIDIA CUDA硬件加速（hevc_nvenc）
    - 相比软件编码快10-50倍
    - 需要支持NVENC的NVIDIA显卡

.INPUTS
    System.String
    接受管道输入的文件或目录路径

.OUTPUTS
    无返回值，输出处理日志和统计信息

.LINK
    FFmpeg文档: https://ffmpeg.org/documentation.html
#>

param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0, HelpMessage = "源路径")]
    [ValidateScript({ Test-Path -LiteralPath $_ }, ErrorMessage = "路径 '{0}' 不存在")]
    [string]$Source,

    [Parameter(Position = 1, HelpMessage = "目标文件夹")]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container }, ErrorMessage = "路径 '{0}' 不存在或不是文件夹")]
    [string]$Destination,

    [ValidateRange(26, 40)]
    [int]$Quality = 30,

    [ValidateSet('copy', 'low', 'high', 'none')]
    [string]$Audio = 'copy'
)

# 支持的视频格式扩展名列表
$VideoExtensions = @('.mp4', '.mkv', '.avi', '.mov', '.wmv', '.flv', '.webm', '.m4v', '.mpg', '.mpeg', '.ts', '.m2ts', '.3gp', '.3g2')

# 根据音频参数构建FFmpeg音频编码选项
$audioOptions = switch ($Audio) {
    'copy' { @('-c:a', 'copy') }
    'low' { @('-c:a', 'aac', '-b:a', '128k') }
    'high' { @('-c:a', 'aac', '-b:a', '320k') }
    'none' { @('-an') }
}

# 获取并验证输入路径
try {
    $inputItem = Get-Item -LiteralPath $Source -ErrorAction Stop
}
catch {
    Write-Error -Message "无法访问源路径" -Category ObjectNotFound
    return
}

if ($inputItem.PSIsContainer) {
    if (-not $Destination) {
        $Destination = $inputItem
    }
    # 处理目录：获取所有视频文件
    $videoFiles = @(Get-ChildItem -LiteralPath $inputItem -File | 
        Where-Object { $_.Extension.ToLower() -in $VideoExtensions })
    
    if ($videoFiles.Count -eq 0) {
        Write-Warning "源路径未找到视频"
        return
    }
    
    Write-Host "找到视频: " -NoNewline
    Write-Host $videoFiles.Count -NoNewline -ForegroundColor Cyan
    Write-Host "个"
}
else {
    if (-not $Destination) {
        $Destination = $inputItem.Parent
    }
    # 处理单个文件
    if ($VideoExtensions -notcontains $inputItem.Extension.ToLower()) {
        Write-Error -Message "文件格式不支持" -Category InvalidData
        return
    }
    $videoFiles = @($inputItem)
}

# 初始化统计对象
$statistics = @{
    Total   = $videoFiles.Count
    Success = 0
    Failed  = 0
    Skipped = 0
}

Write-Host ""
foreach ($videoFile in $videoFiles) {
    $baseName = $videoFile.BaseName
    $extension = $videoFile.Extension
    $current = $videoFiles.IndexOf($videoFile) + 1

    Write-Host "[$current/$($statistics.Total)] 正在处理: " -NoNewline
    Write-Host $videoFile.Name -ForegroundColor Cyan
    
    # 构建输出文件路径
    $outputFile = Join-Path -Path $Destination -ChildPath "${baseName}_hevc${extension}"
    
    # 检查输出文件是否已存在
    if (Test-Path -LiteralPath $outputFile) {
        Write-Warning "跳过，文件已存在"
        $statistics.Skipped++
        continue
    }

    
    # 构建FFmpeg命令参数数组（更安全，避免Invoke-Expression）
    $ffmpegArgs = @(
        '-loglevel', 'error'
        '-stats'
        '-hwaccel', 'cuda'
        '-i', "`"$($videoFile.FullName)`""
        '-c:v', 'hevc_nvenc'
        '-cq', [string]$Quality
    ) + $audioOptions + @("`"$outputFile`"")
    
    # 执行FFmpeg转换
    # Write-Host $ffmpegArgs
    $process = Start-Process -FilePath 'ffmpeg' -ArgumentList $ffmpegArgs -Wait -PassThru -NoNewWindow -RedirectStandardOutput 'NUL'
        
    if ($process.ExitCode -eq 0) {
        Write-Host "完成" -ForegroundColor Green
        $statistics.Success++
    }
    else {
        Write-Error "失败，错误码: $($process.ExitCode)" -Category InvalidData
        $statistics.Failed++
    }
}

# 输出统计结果
Write-Host "`n共 " -NoNewline
Write-Host $statistics.Total -ForegroundColor Cyan -NoNewline
Write-Host " 个视频: 成功 " -NoNewline
Write-Host $statistics.Success -ForegroundColor Green -NoNewline
Write-Host " 个，跳过 " -NoNewline
Write-Host $statistics.Skipped -ForegroundColor Yellow -NoNewline
Write-Host " 个，失败 " -NoNewline
Write-Host $statistics.Failed -ForegroundColor Red -NoNewline
Write-Host " 个"
