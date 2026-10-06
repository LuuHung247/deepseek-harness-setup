# Run elevated (Run as administrator).
#  - forwards 127.0.0.1:80 -> 127.0.0.1:47831 so http://localhost works without a port
#  - removes the legacy "deepseek.harness.local" hosts entry from earlier versions of this setup
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (Select-String -Path $hosts -Pattern 'deepseek\.harness\.local' -Quiet) {
    $kept = Get-Content $hosts | Where-Object { $_ -notmatch 'deepseek\.harness\.local' }
    Set-Content -Path $hosts -Value $kept -Encoding ASCII
    Write-Host "Removed legacy hosts entry"
}
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=80 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=80 connectaddress=127.0.0.1 connectport=47831
Write-Host "--- portproxy ---"; netsh interface portproxy show v4tov4
Write-Host "--- hosts (deepseek.harness.local should be absent) ---"; Select-String -Path $hosts -Pattern 'deepseek\.harness\.local'
Read-Host "Xong. Nhan Enter de dong"
