Write-Host -Foreground "Yellow" "verify O365 sync is not already taking place. If not, then press enter to continue..."
pause
Write-Host -Foreground "Yellow" "Performing O365 Delta Sync..."
Invoke-Command -ComputerName "CHANGE THIS" { Start-ADSyncSyncCycle -PolicyType Delta }
Start-Sleep -Seconds 120
