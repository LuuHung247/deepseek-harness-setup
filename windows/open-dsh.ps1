# Open DeepSeek Harness web UI (starts it under pm2 if not running)
#   open-dsh.ps1                          -> default browser
#   open-dsh.ps1 -ChromeProfile "Profile 1" -> that Chrome profile ("Default", "Profile 1", "Profile 2")
#   open-dsh.ps1 -AllChromeProfiles       -> every Chrome profile (each profile has its own cookie)
param(
    [string]$ChromeProfile,
    [switch]$AllChromeProfiles
)
$log = "$env:USERPROFILE\.pm2\logs\dsh-web-out.log"
$running = Get-NetTCPConnection -LocalPort 47831 -State Listen -ErrorAction SilentlyContinue
if (-not $running) {
    pm2 delete dsh-web 2>$null | Out-Null
    pm2 start "$env:USERPROFILE\.dsh-pm2\ecosystem.config.js" | Out-Null
    for ($i = 0; $i -lt 30 -and -not (Get-NetTCPConnection -LocalPort 47831 -State Listen -ErrorAction SilentlyContinue); $i++) { Start-Sleep 2 }
}
$url = Get-Content $log -ErrorAction SilentlyContinue | Where-Object { $_ -match 'dsh web: (http\S+)' } | Select-Object -Last 1 | ForEach-Object { $Matches[1] }
if (-not $url) { Write-Host "Chua thay URL trong $log"; return }
# Use the friendly domain when it resolves via the hosts file (port 80 -> 47831 via portproxy)
$hosted = Select-String -Path "$env:SystemRoot\System32\drivers\etc\hosts" -Pattern 'deepseek\.harness\.local' -Quiet
if ($hosted) { $url = $url -replace '127\.0\.0\.1:47831', 'deepseek.harness.local' }

$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"
if ($AllChromeProfiles) {
    $ls = Get-Content "$env:LOCALAPPDATA\Google\Chrome\User Data\Local State" -Raw | ConvertFrom-Json
    foreach ($p in $ls.profile.info_cache.PSObject.Properties.Name) {
        Start-Process $chrome -ArgumentList "--profile-directory=`"$p`"", $url
        Start-Sleep 1
    }
} elseif ($ChromeProfile) {
    Start-Process $chrome -ArgumentList "--profile-directory=`"$ChromeProfile`"", $url
} else {
    Start-Process $url
}
