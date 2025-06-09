
function getUsername {
  while(1) {
    $script:input = Read-Host "Please enter the username you need to check in AD"
    
    try {
      Get-Aduser -Identity $script:input -Properties * | Select samaccountname,displayname,mail,description,proxyaddresses,distinguishedname,enabled,department 
      }
    catch {
      Write-Error "User not found"
        }

    $loopy = Read-Host "Proceed?(Y/N)"
    if ( $loopy -in @("y","Y")) {
      parseInfo
      }
    }
}


function parseInfo {
  $termDate = Read-Host "Enter TERM date (YYYYMMDD)"
  $path = $PSScriptRoot + "..\email-deactivation-O365\deactivate-users.csv"
  try {
    Get-AdUser -Identity $script:input -Properties * | Select mail,samaccountname | ForEach-Object { 
      $email = $_.mail
      $username = $_.samaccountname
      $newEmail = "TERM-$termDate-$email"
      # Change this !!!!
      $termedDisplayname = $newEmail -Replace '@CompanyName.com', ''

      Write-Host -Foreground "yellow" "`nUsername: $username`nEmail: $email`nTerm display name: $termedDisplayname`nTerm email: $newEmail`n" 

      $userList += [PSCustomObject]@{
        Login = $username
        Email = $email
        DeactivatedEmail = $newEmail
        Alias = $termedDisplayname
        }
      }
    }
    catch {
      Write-Error "Something went wrong while adding TERM to email and username"
    }
    try {
    $userList | Export-Csv -Path "$path" -NoTypeInformation
  Write-Host -Foreground "green" "Data has been parsed to CSV"
    }
    catch {
      Write-Error "Something went wrong with the CSV parsing"
    }
}

getUsername


