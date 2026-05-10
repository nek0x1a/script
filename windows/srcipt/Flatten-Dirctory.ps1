[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String]$Path,

    [Int32]$MaxDepth = 1,

    [switch]$WithParentName
)

process {
    $ExcessiveFiles = Get-ChildItem -Path $Path -File -Recurse -Force | 
    Where-Object {
        $RelativePath = $_.FullName.Substring($Path.Length).TrimStart([System.IO.Path]::DirectorySeparatorChar)
        $CurrentDepth = ($RelativePath.Split([System.IO.Path]::DirectorySeparatorChar) | Where-Object { $_ }).Count - 1
        $CurrentDepth -gt $MaxDepth
    }
    if ($ExcessiveFiles) {
        Write-Host "超过最大深度限制: $MaxDepth" -ForegroundColor Red
        return
    }
    $Files = Get-ChildItem -Path $Path -Recurse -File -Force | Where-Object {
        $_.DirectoryName -ne $Path
    }
    $Count = @{'total' = $Files.Count; 'seccess' = 0; 'skip' = 0; 'failure' = 0 }
    $Files | ForEach-Object {
        $CurrentFile = $_
        if ($WithParentName) {
            $TargetPath = Join-Path $Path "$($CurrentFile.Directory.Name)-$($CurrentFile.Name)"
        }
        else {
            $TargetPath = Join-Path $Path "$($CurrentFile.Name)"
        }
        if (Test-Path $TargetPath) {
            Write-Host "已存在同名文件: $($TargetPath.Name)"
            $Count['skip'] += 1
            continue
        }

        try {
            Move-Item -Path $CurrentFile -Destination $TargetPath -Force
            $Count['seccess'] += 1
        }
        catch {
            Write-Error "无法移动文件 ${CurrentFile}: $($_.Exception.Message)"
            $Count['failure'] += 1
        }
    }
    Write-Host "成功 " -NoNewline
    Write-Host $Count['seccess'] -ForegroundColor Green -NoNewline
    Write-Host " | 跳过 " -NoNewline
    Write-Host $Count['skip'] -ForegroundColor Yellow -NoNewline
    Write-Host " | 失败 " -NoNewline
    Write-Host $Count['failure'] -ForegroundColor Red -NoNewline
    Write-Host " / 总计 $($Count['total'])"
}