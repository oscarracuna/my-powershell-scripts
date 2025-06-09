$InputFile = Import-CSV "C:\email-deactivation-O365\deactivate-users.csv"
Foreach ($User in $InputFile) {
  $Login = $User.Login
  $Email = $User.Email
  $DeactivatedEmail = $User.DeactivatedEmail
  $Alias = $User.Alias
  $Description = $User.Description
  Write-Host -Foreground "Yellow" "Blocking O365 sign in..."

  $params = @{
	  accountEnabled = $false
  }

  Update-MgUser -UserId $Email -BodyParameter $params
  Start-Sleep -Seconds 5
  Write-Host -Foreground "yellow" "Renaming Email to Deactivated Email Name..."

  Update-MgUser -UserId $Email -UserPrincipalName $DeactivatedEmail
  Start-Sleep -Seconds 30

  Write-Host -Foreground "yellow" "Renaming O365 Email Alias..."
  Set-Mailbox -Identity $Email -Alias $Alias
  Start-Sleep -Seconds 30

  Write-Host -Foreground "yellow" "Hiding Deactivated Email from Address Lists..."
  Set-Mailbox -Identity $Email -HiddenFromAddressListsEnabled $true
  Start-Sleep -Seconds 20

  Write-Host -Foreground "yellow" "Converting $Email User Mailbox to Shared Mailbox..."
  Set-Mailbox $Email -Type Shared
  Start-Sleep -Seconds 30

  Write-Host -Foreground "Yellow" "Please Wait one minute. Removing O365 Email Aliases..."
  Set-Mailbox -Identity $Email -EmailAddresses SMTP:$DeactivatedEmail
  Start-Sleep -Seconds 30


  Write-Host -Foreground "Yellow" "Removing O365 Email License..."
  $currentLicense = Get-MgUserLicenseDetail -UserId $DeactivatedEmail | Select SkuId
  Set-MgUserLicense -UserId $DeactivatedEmail -RemoveLicenses $currentLicense.SkuId -AddLicenses @{}
  start-sleep -seconds 20
}
Write-Host -Foreground "cyan" "O365 Deactivations Completed!"
