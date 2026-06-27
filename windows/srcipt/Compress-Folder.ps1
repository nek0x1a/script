<#
.SYNOPSIS
    使用7-Zip Zstandard对指定文件夹内的子文件夹进行批量压缩。

.DESCRIPTION
    扫描输入路径下的所有子文件夹（包文件夹），根据选择的压缩模式将其分别压缩为独立的归档文件。
    支持pack、game、comic三种模式，可控制是否删除原始包文件夹。

.PARAMETER Source
    要扫描的输入路径。脚本将处理此路径下的所有子文件夹。

.PARAMETER Destination
    压缩文件输出目录。如果未指定，则默认与输入路径相同。

.PARAMETER Mode
    压缩模式。可选：'pack'（标准ZIP）、'game'（高压缩7z-Zstd）、'comic'（扁平ZIP）。
    默认值为 'pack'。

.PARAMETER Delete
    开关。若指定，则压缩成功后删除原始包文件夹。

.EXAMPLE
    .\Compress-Folder.ps1 -Source "D:\A" -Mode game -Destination "E:\Backup" -Delete
    说明：以'game'模式压缩D:\A下的所有子文件夹，输出到E:\Backup，并删除原文件夹。

.EXAMPLE
    .\Compress-Folder.ps1 -Source "D:\A" -Mode comic
    说明：以'comic'模式压缩D:\A下的所有子文件夹，输出到D:\A，并保留原文件夹。

.NOTES
    需要预先安装 7zip-zstd，并确保 '7z' 命令可用。
    需要 PowerShell 7.0+
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory, ValueFromPipeline, Position = 0, HelpMessage = "需要扫描的文件夹")]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container }, ErrorMessage = "路径 '{0}' 不存在或不是文件夹")]
    [string]$Source,

    [Parameter(Position = 1, HelpMessage = "输出文件夹")]
    [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container }, ErrorMessage = "路径 '{0}' 不存在或不是文件夹")]
    [string]$Destination,

    [Parameter(HelpMessage = "压缩模式")]
    [ValidateSet('pack', 'game', 'comic')]
    [string]$Mode = 'pack',

    [Parameter(HelpMessage = "删除源文件")]
    [switch]$Delete
)


# 验证 7z 命令是否可用
if (-not (Get-Command '7z' -ErrorAction SilentlyContinue)) {
    Write-Error "未找到命令: 7z`n请安装 7zip-zstd 并添加到环境变量" -Category ObjectNotFound -ErrorAction Stop
}

# 定义压缩模式的配置
$CompressionConfig = @{
    pack  = @{
        Args      = 'a', '-tzip', '-mx=5', '-sccUTF-8', '-bd'
        Extension = '.zip'
    }
    game  = @{
        Args      = 'a', '-t7z', '-m0=zstd', '-mx=11', '-sccUTF-8', '-bd'
        Extension = '.7z'
    }
    comic = @{
        Args      = 'a', '-tzip', '-mx=5', '-sccUTF-8', '-bd'
        Extension = '.zip'
    }
}

$ComicModeIncludeExtensions = '.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.avif', '.jxr'
$ComicModeIncludeNames = 'comicinfo.xml'
$GlobalExcludeNames = 'thumbs.db', '.ds_store', '__macosx'


function Get-CompressionConfig {
    <#
    .SYNOPSIS
        返回指定压缩模式的配置对象。
    .PARAMETER Mode
        压缩模式 ('pack', 'game', 'comic')
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('pack', 'game', 'comic')]
        [string]$Mode
    )

    return $CompressionConfig[$Mode]
}


function Get-FilesForCompression {
    <#
    .SYNOPSIS
        获取用于压缩的文件列表，根据模式和排除列表进行过滤。
    .PARAMETER PackagePath
        包文件夹路径。
    .PARAMETER Mode
        压缩模式。
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.IO.DirectoryInfo]$PackagePath,

        [Parameter(Mandatory)]
        [ValidateSet('pack', 'game', 'comic')]
        [string]$Mode
    )

    $getItemParams = @{
        LiteralPath = $PackagePath
        Force       = $true
    }

    if ($Mode -eq 'comic') {
        # Comic模式：仅包含图片和comicinfo.xml
        Get-ChildItem @getItemParams -Recurse -File |
        Where-Object {
            $_.Name -notin $GlobalExcludeNames -and
            ($_.Extension.ToLower() -in $ComicModeIncludeExtensions -or $_.Name.ToLower() -in $ComicModeIncludeNames)
        }
    }
    else {
        # Pack和Game模式：所有子项，排除系统文件
        Get-ChildItem @getItemParams |
        Where-Object { $_.Name.ToLower() -notin $GlobalExcludeNames }
    }
}


function Invoke-Compression {
    <#
    .SYNOPSIS
        对单个包文件夹执行压缩操作。
    .PARAMETER PackagePath
        要压缩的包文件夹完整路径。
    .PARAMETER Destination
        输出目录路径。
    .PARAMETER Mode
        压缩模式。
    .PARAMETER DeleteSource
        是否在成功后删除源文件夹。
    .OUTPUTS
        返回一个hashtable，包含 Status (Success/Failed/Skipped) 和 Message
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
        [string]$PackagePath,

        [Parameter(Mandatory)]
        [ValidateScript({ Test-Path -LiteralPath $_ -PathType Container })]
        [string]$Destination,

        [Parameter(Mandatory)]
        [ValidateSet('pack', 'game', 'comic')]
        [string]$Mode,

        [Parameter()]
        [bool]$DeleteSource
    )

    $packageName = Split-Path -Path $PackagePath -Leaf
    $config = Get-CompressionConfig -Mode $Mode
    $outputFile = Join-Path -Path $Destination -ChildPath "$packageName$($config.Extension)"

    # 检查同名压缩文件是否已存在
    if (Test-Path -LiteralPath $outputFile) {
        Write-Warning "跳过：同名文件已存在"
        return @{ Status = 'Skipped'; Message = '文件已存在' }
    }

    # 获取需要压缩的文件列表
    $filesForCompress = @(Get-FilesForCompression -PackagePath $PackagePath -Mode $Mode)

    if ($filesForCompress.Count -eq 0) {
        Write-Warning "没有可被压缩的文件"
        return @{ Status = 'Skipped'; Message = '没有可压缩的文件' }
    }

    # 执行压缩
    try {
        $tempFileList = [System.IO.Path]::GetTempFileName()
        
        try {
            # 将文件清单写入临时文件
            $filesForCompress.FullName | 
            Set-Content -LiteralPath $tempFileList -Encoding UTF8
            
            # 构建7z命令参数
            $processArguments = @($config.Args) + @("`"$outputFile`"", "`"@$tempFileList`"")
            
            # 调用7z进程
            $process = Start-Process '7z' -ArgumentList $processArguments -Wait -PassThru -NoNewWindow -RedirectStandardOutput 'NUL'

            if ($process.ExitCode -ne 0) {
                throw "7z 返回错误代码: $($process.ExitCode)"
            }

            # 删除源文件夹
            if ($DeleteSource) {
                try {
                    Remove-Item -LiteralPath $PackagePath -Recurse -Force
                    Write-Host "已删除原文件夹" -ForegroundColor Gray
                }
                catch {
                    Write-Warning "删除原文件夹失败: $_"
                }
            }

            return @{ Status = 'Success'; Message = '压缩成功' }
        }
        finally {
            if (Test-Path -LiteralPath $tempFileList) {
                Remove-Item -LiteralPath $tempFileList -Force
            }
        }
    }
    catch {
        Write-Error "压缩失败: $_" -Category InvalidData
        return @{ Status = 'Failed'; Message = "压缩失败: $_" }
    }
}


# 设置输出路径
if (-not $Destination) {
    $Destination = $Source
}

if (-not (Test-Path -LiteralPath $Destination)) {
    try {
        New-Item -Path $Destination -ItemType Directory -Force | Out-Null
    }
    catch {
        Write-Error "无法创建输出路径：$_" -Category WriteError -ErrorAction Stop
    }
}

# 获取所有待处理文件夹
$packageFolders = @(Get-ChildItem -LiteralPath $Source -Directory)

if ($packageFolders.Count -eq 0) {
    Write-Warning "未找到任何子文件夹"
    return
}

# 初始化统计对象
$statistics = @{
    Total   = $packageFolders.Count
    Success = 0
    Failed  = 0
    Skipped = 0
}

Write-Host "找到 " -NoNewline
Write-Host $statistics.Total -ForegroundColor Cyan -NoNewline
Write-Host " 个文件夹，压缩模式: " -NoNewline
Write-Host $Mode -ForegroundColor Yellow

# 处理每个文件夹
$packageFolders | ForEach-Object {
    $current = $packageFolders.IndexOf($_) + 1
    Write-Host "`n[$current/$($statistics.Total)] 正在处理: " -NoNewline
    Write-Host $_.Name -ForegroundColor Cyan

    $result = Invoke-Compression -PackagePath $_.FullName -Destination $Destination -Mode $Mode -DeleteSource $Delete

    # 更新统计
    $statistics[$result.Status]++
    
    Write-Host "完成" -ForegroundColor Green
}

# 输出统计结果
Write-Host "`n共 " -NoNewline
Write-Host $statistics.Total -ForegroundColor Cyan -NoNewline
Write-Host " 个文件夹: 成功 " -NoNewline
Write-Host $statistics.Success -ForegroundColor Green -NoNewline
Write-Host " 个，跳过 " -NoNewline
Write-Host $statistics.Skipped -ForegroundColor Yellow -NoNewline
Write-Host " 个，失败 " -NoNewline
Write-Host $statistics.Failed -ForegroundColor Red -NoNewline
Write-Host " 个"
