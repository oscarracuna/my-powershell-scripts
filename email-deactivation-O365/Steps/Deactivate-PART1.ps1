$InputFile = Import-CSV "C:\Email-Deactivation-O365\deactivate-users.csv"
Foreach ($User in $InputFile) {
  $Login = $User.Login

  $Email = $User.Email

  $DeactivatedEmail = $User.DeactivatedEmail

  $Description = $User.Description


  Write-Host -Foreground "Yellow" "Removing $Email from AD login $Login ..."
  Set-ADUser $Login -Remove @{Mail="$Email"}
  Start-Sleep -Seconds 5

  Set-ADUser $Login -Remove @{ProxyAddresses="SMTP:$Email"}
  Start-Sleep -Seconds 5
}
