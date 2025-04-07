# 获取 Github 仓库 Releases
function Get-GithubAsset {
    param (
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline,
            HelpMessage = "Github 仓库"
        )]
        [ValidatePattern('.+\/.+')]
        [String]$Repository,

        [Parameter(
            Position = 1,
            HelpMessage = "版本 Tag"
        )]
        [PSDefaultValue(Help = "latest")]
        [String]$Tag = "latest",

        [Parameter(
            Position = 2,
            HelpMessage = "下载文件名正则匹配"
        )]
        [PSDefaultValue(Help = ".*")]
        [String]$Pattern = '.*',

        [Parameter(
            Position = 3,
            HelpMessage = "WebClient 实例"
        )]
        [PSDefaultValue(Help = "新建 WebClient")]
        [System.Net.WebClient]$Downloader = (New-Object System.Net.WebClient)
    )
    
    # 构建文件列表
    $DownloadList = @()
    $QueryApi = "https://api.github.com/repos/$($Repository)/releases/$($Tag)"
    $Response = Invoke-WebRequest -URI $QueryApi | ConvertFrom-Json
    $Response.assets | Where-Object {
        $_.name -match $Pattern
    } | ForEach-Object {
        $DownloadList += @{
            Name = $_.name
            Url  = $_.browser_download_url
        }
    }

    # 获取文件
    $DownloadList | ForEach-Object {
        if (Test-Path $_.Name) {
            Write-Host "文件已存在: " -NoNewline
            Write-Host $_.Name -ForegroundColor Yellow
        }
        else {
            Write-Host "下载 " -NoNewline
            Write-Host $_.Name -ForegroundColor Cyan -NoNewline
            Write-Host "..."
            $Downloader.DownloadFile($_.Url, (Join-Path $PWD $_.Name))
        }
    }
}

Export-ModuleMember -Function Get-GithubAsset
