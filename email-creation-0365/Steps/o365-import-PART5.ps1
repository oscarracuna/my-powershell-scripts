$InputFile = Import-CSV "C:\Email-Creation-O3365\Import-Users.csv"
Foreach ($User in $InputFile)
{
$Login = $User.Login
$Email = $User.Email
Write-Host -Foreground "Yellow" "Enabling Archive for $Email ..."
Enable-Mailbox (Get-Mailbox -Identity $Email | select guid).guid.guid -Archive
Start-Sleep -Seconds 2
}
Write-Host -Foreground "Cyan" "O365 Email Import Completed!"
