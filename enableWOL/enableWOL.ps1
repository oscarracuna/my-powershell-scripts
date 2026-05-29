
Get-NetAdapterPowerManagement -Name "Ethernet*"| Select Name, WakeOnMagicPacket, WakeOnPattern

Try {
  Write-Host -Foreground Yellow "Enabling WoL."
  Get-NetAdapter -Name "Ethernet*"  | Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -WakeOnPattern Enabled
  Write-Host -Foreground Green "[x] WoL enabled on all Ethernet Ports."
}
Catch {
  Write-Error "Unable to set up WoL. Please check the name of the NetAdapters or enable manually."
  exit 1
}

$result = Get-NetAdapterPowerManagement -name "Ethernet*" | Select WakeOnMagicPacket

If ($result.WakeOnMagicPacket -eq "Enabled" -and $result.WakeOnPattern -eq "Enabled") {
  Write-Host "it worked"
  exit 0 
}
