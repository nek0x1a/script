[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String]$Source,

    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String]$Target,

    [switch]$Delete
)

process {
    if (-not (Get-Command 7z -ErrorAction SilentlyContinue)) {
        Write-Error "未找到 7z"
        return
    }

    $TargetPath = Join-Path $Target (Get-Date -Format "yyyyMMdd")
    if (-not (Test-Path $TargetPath)) {
        New-Item -Path $TargetPath -ItemType Directory -Force | Out-Null
    }

    Write-Host "漫画批量打包" -ForegroundColor Cyan
    Write-Host "输入目录: $Source"
    Write-Host "输出目录: $TargetPath"
    Write-Host "删除源文件: $Delete"

    $IncludeFiles = @('*.bmp', '*.jpg', '*.jpeg', '*.png', '*.gif', '*.webp')
    $PaddingDirs = @(Get-ChildItem $Source -Directory)
    $Count = @{'total' = $PaddingDirs.Count; 'seccess' = 0; 'skip' = 0; 'failure' = 0 }

    $PaddingDirs | ForEach-Object {
        $CurrentDir = $_
        $PackageName = "$($CurrentDir.Name).zip"
        $PackagePath = Join-Path $TargetPath $PackageName
        
        $CurrentIndex = $Count['seccess'] + $Count['skip'] + $Count['failure'] + 1
        Write-Host "[$CurrentIndex/$($Count['total'])] $($CurrentDir.Name)"
        if (Test-Path -LiteralPath "$PackagePath") {
            Write-Host "  文件已存在：$PackagePath" -ForegroundColor Yellow
            $Count['skip'] += 1
            return
        }

        $FilesToPack = Get-ChildItem -LiteralPath $CurrentDir -Recurse -File -Include $IncludeFiles
        if (-not $FilesToPack) {
            Write-Host "  未发现图片: $($CurrentDir.Name)" -ForegroundColor Yellow
            $Count['skip'] += 1
            return
        }

        & 7z a -tzip -mx0 "$PackagePath" $FilesToPack | Out-Null
        $ResultCode = $LASTEXITCODE

        if ($ResultCode -ne 0) {
            Write-Host "  7z 异常退出，代码：$ResultCode" -ForegroundColor Red
            $Count['failure'] += 1
            return
        }
        if ($Delete) {
            Remove-Item -LiteralPath $CurrentDir -Recurse -Force
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