[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript({ Test-Path -Path $_ -PathType Container })]
    [string]$Path,

    [switch]$Recurse
)
process {
    $Count = 0
    if ($Recurse) {
        $Folders = Get-ChildItem -Path $Path -Directory -Recurse -Force
    }
    else {
        $Folders = Get-ChildItem -Path $Path -Directory -Force
    }
    $Folders | Sort-Object FullName -Descending | ForEach-Object {
        $CurrentFolder = $_
        $FirstFile = Get-ChildItem -Path $CurrentFolder -Recurse -File -Force -ErrorAction Continue | Select-Object -First 1
        if (-not $FirstFile) {
            Remove-Item -Path $CurrentFolder -Recurse -Force -ErrorAction Continue
            $Count += 1
        }
    }
    Write-Host "删除空文件夹 " -NoNewline
    Write-Host $Count -NoNewline -ForegroundColor Green
    Write-Host " 个"
}