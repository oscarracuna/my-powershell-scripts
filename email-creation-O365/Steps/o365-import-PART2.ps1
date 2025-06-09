$InputFile = Import-CSV "$PSScriptRoot\import-users.csv"
Foreach ($User in $InputFile) {
  $Login = $User.Login
  $Email = $User.Email
  Write-Host -Foreground "Yellow" "Attaching Email to Mail AD Attribute for $Login..."
  Set-ADUser $Login -EmailAddress "$Email"
  Start-Sleep -Seconds 2
  Write-Host -Foreground "yellow" "Attaching Email to ProxyAddresses AD Attribute for $Login..."
  Set-ADUser $Login -Add @{ProxyAddresses="SMTP:$Email"}
  Start-Sleep -Seconds 2
}
Start-Sleep -Seconds 25
