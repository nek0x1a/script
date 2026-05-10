[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [String]$Path,

    [switch]$WithParentName,

    [switch]$SubDirectories
)

process {
    $Targets = if ($SubDirectories) {
        Get-ChildItem -Path $Path -Directory
    }
    else {
        Get-Item -Path $Path
    }
    $Targets | ForEach-Object {
        $Folder = $_
        Write-Host "处理 $($Folder)"
        Get-ChildItem -Path $Folder | ForEach-Object {
            $Item = $_
            $NewName = if ($WithParentName) {
                "$($Folder.Name)-$($Item.Name)"
            }
            else {
                $Item.Name
            }
            $Destination = Join-Path -Path $($Folder.Parent) -ChildPath $NewName

            if (Test-Path $Destination) {
                Write-Warning "  文件/文件夹已存在: $NewName" -ForegroundColor Yellow
                return
            }

            try {
                Move-Item -Path $Item -Destination $Destination -Force
            }
            catch {
                Write-Host "  无法移动 $($Item): $($_.Exception.Message)" -ForegroundColor Red
            }
        }
        if (-not (Get-ChildItem -Path $Folder -Force).Count) {
            Remove-Item -Path $Folder -Force -ErrorAction Continue
        }
        else {
            Write-Warning "  文件夹不为空: $Folder" -ForegroundColor Yellow
        }
    }
}
