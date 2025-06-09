Write-Host -Foreground "Yellow" "Verify O365 Sync is not already taking place. If not, then press enter..."
pause
Write-Host -Foreground "Yellow" "Performing O365 Delta Sync..."
Invoke-Command -ComputerName "CHANGE THIS" { Start-AdSyncSyncCyle -PolicyType Delta }
Start-Sleep -Seconds 45
