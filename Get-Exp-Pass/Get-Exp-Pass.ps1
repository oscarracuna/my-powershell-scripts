while (1) {
  $username = Read-Host "Enter username"
  $result = Get-AdUser -Identity $username -Properties "DisplayName", "msDS-UserPasswordExpiryTimeComputed" | 
  Select-Object -Property "DisplayName", @{Name="ExpiryDate";Expression{[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed")}}
  $result | Format-Table -AutoSize
}

