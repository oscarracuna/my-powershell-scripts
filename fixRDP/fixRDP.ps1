$RegPath = "HKLM:\Software\Policies\Microsoft\Windows NT\Terminal Services\Client"
$Name = "RedirectionWarningDialogVersion"
$Value = 1

# Ensure the registry path exists
if (!(Test-Path $RegPath)) {
    New-Item -Path $RegPath -Force | Out-Null
} else {
  Write-Host  "Registry already exists"
  exit 1
}

# Create or update the DWORD value
New-ItemProperty -Path $RegPath -Name $Name -Value $Value -PropertyType DWORD -Force | Out-Null

Write-Host "Registry value set successfully."
exit 0
