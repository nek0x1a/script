[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [String]$Source,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [String]$Target,

    [ValidateSet('h264', 'hevc', 'av1', IgnoreCase = $true)]
    [String]$VideoFormat = 'h264',

    [ValidateSet('copy', 'remove', 'aac', IgnoreCase = $true)]
    [String]$AudioFormat = 'copy',

    [ValidateSet('cpu', 'nvidia', 'amd', 'intel', IgnoreCase = $true)]
    [String]$Hardware = 'cpu',

    [ValidateSet('low', 'medium', 'high', IgnoreCase = $true)]
    [String]$Quality = "low",

    [switch]$DeleteSource
)

process {
    if (-not (Get-Command FFmpeg -ErrorAction SilentlyContinue)) {
        Write-Error "未找到 FFmpeg"
        return
    }

    $VideoFormat = $VideoFormat.ToLower()
    $AudioFormat = $AudioFormat.ToLower()
    $Hardware = $Hardware.ToLower()
    $VideoDecoder = @{
        'cpu'    = $null
        'nvidia' = "cuda"
        'amd'    = "amf"
        'intel'  = "qsv"
    }[$Hardware]
    if ($VideoDecoder) {
        $VideoDecoderArgs = @('-hwaccel', $VideoDecoder)
    }
    else {
        $VideoDecoderArgs = @()
    }

    $VideoEncoder = @{
        'cpu'    = @{ 'h264' = 'libx264'; 'hevc' = 'libx265'; 'av1' = 'libsvtav1' }
        'nvidia' = @{ 'h264' = 'h264_nvenc'; 'hevc' = 'hevc_nvenc'; 'av1' = 'av1_nvenc' }
        'amd'    = @{ 'h264' = 'h264_amf'; 'hevc' = 'hevc_amf'; 'av1' = 'av1_amf' }
        'intel'  = @{ 'h264' = 'h264_qsv'; 'hevc' = 'hevc_qsv'; 'av1' = 'av1_qsv' }
    }[$Hardware][$VideoFormat]

    $AudioArgs = switch ($AudioFormat) {
        'copy' { @('-c:a', 'copy') }
        'remove' { @('-an') }
        'aac' { @('-c:a', 'aac', '-b:a', '128k') }
    }

    $QualityNum = @{
        'cpu'    = @{
            'h264' = @{ 'low' = 24; 'medium' = 24; 'high' = 24 }
            'hevc' = @{ 'low' = 25; 'medium' = 25; 'high' = 25 }
            'av1'  = @{ 'low' = 32; 'medium' = 32; 'high' = 32 }
        }
        'nvidia' = @{
            'h264' = @{ 'low' = 30; 'medium' = 30; 'high' = 30 }
            'hevc' = @{ 'low' = 30; 'medium' = 30; 'high' = 30 }
            'av1'  = @{ 'low' = 34; 'medium' = 34; 'high' = 34 }
        }
        'amd'    = @{
            'h264' = @{ 'low' = 24; 'medium' = 24; 'high' = 24 }
            'hevc' = @{ 'low' = 28; 'medium' = 28; 'high' = 28 }
            'av1'  = @{ 'low' = 24; 'medium' = 24; 'high' = 24 }
        }
        'intel'  = @{
            'h264' = @{ 'low' = 24; 'medium' = 24; 'high' = 24 }
            'hevc' = @{ 'low' = 24; 'medium' = 24; 'high' = 24 }
            'av1'  = @{ 'low' = 24; 'medium' = 24; 'high' = 24 }
        }
    }[$Hardware][$VideoFormat][$Quality]
    $QualityArgs = switch ($AudioFormat) {
        'cpu' { @('-rcf', $QualityNum) }
        'nvidia' { @('-cq', $QualityNum) }
        'amd' { @('-qp_i', $QualityNum, '-qp_p', $QualityNum) }
        'intel' { @('-global_quality', $QualityNum) }
    }

    Write-Host "视频批量转换" -ForegroundColor Cyan
    Write-Host "输入目录: $Source"
    Write-Host "输出目录: $Target"
    Write-Host "视频格式: $VideoFormat"
    Write-Host "视频解码: $VideoDecoder"
    Write-Host "视频编码: $VideoEncoder"
    Write-Host "视频质量: $QualityNum"
    Write-Host "音频模式: $AudioFormat"
    Write-Host "删除源文件: $DeleteSource"

    $Extensions = @('*.mp4', '*.mkv', '*.avi', '*.mov', '*.flv', '*.wmv', '*.webm', '*.m4v')
    $Files = @(Get-ChildItem -Path "$Source\*" -Include $Extensions -File)

    $Count = @{'total' = $Files.Count; 'seccess' = 0; 'skip' = 0; 'failure' = 0 }

    $Files | ForEach-Object {
        $CurrentFile = $_
        $OutputFileName = "Convert_$($CurrentFile.BaseName).mp4" # 统一输出为 mp4 容器
        $OutputPath = Join-Path $Target $OutputFileName
        $currentIndex = $Count['seccess'] + $Count['skip'] + $Count['failure'] + 1
        Write-Host "[$currentIndex/$($Count['total'])] $($CurrentFile.Name)"

        if (Test-Path $OutputPath) {
            Write-Host "  文件已存在：$OutputPath" -ForegroundColor Yellow
            $Count['skip'] += 1
            return
        }

        $FFmpegArgs = $VideoDecoderArgs + @(
            '-loglevel', 'quiet', '-hide_banner',
            '-i', "`"$CurrentFile`"",
            '-c:v', $VideoEncoder
        ) + $QualityArgs + $AudioArgs + @("`"$OutputPath`"")
        $Result = Start-Process ffmpeg -ArgumentList $FFmpegArgs -Wait -NoNewWindow -PassThru

        if ($Result.ExitCode -ne 0) {
            Write-Host "  FFmpeg 异常退出，代码：$($Result.ExitCode)" -ForegroundColor Red
            $Count['failure'] += 1
            return
        }
        elseif ($DeleteSource) {
            Remove-Item -Path $CurrentFile -Force
        }
        $Count['seccess'] += 1
    }
    Write-Host "成功 " -NoNewline
    Write-Host $Count['seccess'] -ForegroundColor Green -NoNewline
    Write-Host " | 跳过 " -NoNewline
    Write-Host $Count['skip'] -ForegroundColor Yellow -NoNewline
    Write-Host " | 失败 " -NoNewline
    Write-Host $Count['failure'] -ForegroundColor Red -NoNewline
    Write-Host " / 总计 $($Count['total'])"
}