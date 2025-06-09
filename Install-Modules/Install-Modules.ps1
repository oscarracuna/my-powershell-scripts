Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

Write-Host -Foreground "Yellow" "This has to be ran as admin, so keep that in mind"

# Install Graph
Write-Host -Foreground "Yellow" "Installing Graph..."
Install-Module Microsoft.Graph -Scope CurrentUser -Repository PSGallery -Force


#Install Exchange
Write-Host -Foreground "Yellow" "Installing Exchange..."
Install-Module -Name ExchangeOnlineManagement

#Install ADSyncTools
Write-Host -Foreground "Yellow" "Installing ADSyncTools..."
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Install-Module -Name ADSyncTools

#Import AD module 
Import-Module ActiveDirectory

Write-Host -Foreground "Green" "All set!"
pause

