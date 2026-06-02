param([String[]]$DriveNames)

Function mapDrive {

  foreach ($drive in $DriveNames) {
    $usedLetters = (Get-PSDrive -PSProvider FileSystem).Name 
    $alphabetArray = [char[]](65..90)
    $availableLetter = ($alphabetArray | Where-Object {$_ -notin $usedLetters})[0]
    # $availableLetter = ("E".."Z" | Where-Object {$_ -notin $usedLetters})[0]

    if (-not $availableLetter) {
      Write-Error "No available letters for some reason. Check with Get-PsDrive."
      return
    }
    
    Try {
      $preLocalPath = ":"
      $localPath = $availableLetter + $preLocalPath
      New-SmbMapping -LocalPath $localPath -RemotePath $drive -Persistent $true
    }
    Catch {
      Write-Error "Error mapping drive $drive."
      exit 1
    }
  }
  restartExplorer
 }

 Function restartExplorer {
   Stop-Process -Name "explorer" -Force; Start-Process "explorer"
   Write-Host -Foreground Green "Drive(s) added successfully."
   exit 0
 }
 mapDrive

