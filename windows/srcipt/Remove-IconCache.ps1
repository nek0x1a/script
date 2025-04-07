$IconCachePath = "${env:LOCALAPPDATA}\iconCache.db"
$ThumbCachePath = "${env:LOCALAPPDATA}\Microsoft\Windows\Explorer\thumbcache_*.db"

if (Test-Path $IconCachePath) {
    Remove-Item $IconCachePath -Force
}
if (Test-Path $ThumbCachePath) {
    Remove-Item $ThumbCachePath -Force -Recurse
}
