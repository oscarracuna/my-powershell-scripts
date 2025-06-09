$InputFile = Import-CSV "$PSScriptRoot\deactivate-users.csv"
Foreach ($User in $InputFile) {
  $Login = $User.Login

  $Email = $User.Email

  $DeactivatedEmail = $User.DeactivatedEmail

  $DeactivatedEmail2 = $User.DeactivatedEmail2

  $Description = $User.Description

  Write-Host -Foreground "Yellow" "Restoring O365 Email $Email next..."
  $deletedUser = Get-MgDirectoryDeletedItemAsUser | Where-Object { $_.mail -eq $Email }
  Restore-MgDirectoryDeletedItem -DirectoryObjectId $deletedUser.Id
  Start-Sleep -seconds 10

  Write-Host -foreground "yellow" "Clearing ImmutableID for $Email..."
  Clear-ADSyncToolsOnPremisesAttribute $Email -All
  Clear-ADSyncToolsOnPremisesAttribute -Identity $Email -onPremisesImmutableId

}
