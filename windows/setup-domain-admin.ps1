# Run elevated. Maps deepseek.harness.local -> 127.0.0.1 and forwards 127.0.0.1:80 -> 127.0.0.1:47831
$hosts = "$env:SystemRoot\System32\drivers\etc\hosts"
if (-not (Select-String -Path $hosts -Pattern 'deepseek\.harness\.local' -Quiet)) {
    Add-Content -Path $hosts -Value "`r`n127.0.0.1`tdeepseek.harness.local"
}
netsh interface portproxy delete v4tov4 listenaddress=127.0.0.1 listenport=80 2>$null | Out-Null
netsh interface portproxy add v4tov4 listenaddress=127.0.0.1 listenport=80 connectaddress=127.0.0.1 connectport=47831
Write-Host "--- hosts ---"; Select-String -Path $hosts -Pattern 'deepseek\.harness\.local'
Write-Host "--- portproxy ---"; netsh interface portproxy show v4tov4
Read-Host "Xong. Nhan Enter de dong"
