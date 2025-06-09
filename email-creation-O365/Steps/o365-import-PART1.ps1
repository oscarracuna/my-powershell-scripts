# Script reads from 'import-users.csv' to see which email addresses already exist in O365
# Shoutout to Lamar Soto!


$User_Input = Read-Host "Do you want to obtain a fresh copy of O365 mailbox information?"
If("$User_Input" -eq "Yes") {
    write-host -foreground "cyan" "Obtaining fresh O365 mailbox information..."
    Get-EXOMailbox -Resultsize Unlimited | Select-Object DisplayName,EmailAddresses | Export-Csv "$PSScriptRoot\Email-Dump.csv" –NoTypeInformation
}
else {
  Write-Output "Skipping New Data"
  }

$InputFile1 = Import-CSV "$PSScriptRoot\Import-Users.csv"
$InputFile2 = Import-CSV "$PSScriptRoot\o365-outall.csv"
foreach ($User in $InputFile1) {
$Email = $User.Email
write-host -foreground "yellow" "Verifying if $Email is unique in O365..."
$IdentityCheck  = $InputFile2 | Where-Object {$_.EmailAddresses -like "*$Email*"} 

if($IdentityCheck){
write-host -foreground "red" "WARNING: $Email already exists!..."
} else {
write-host -foreground "green" "GOOD: $Email is safe to create!..."
  }
}
write-host -foreground "cyan" "NOTE: If any email addresses already exist, kill script (CTRL+C) & fix it.`n If all results are 'GOOD', press enter to continue."
pause
