# ========================================="
# Script created and maintained by Óscar A."
# ========================================="

# Enforce Admin Check
If (-NOT ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {

    Write-Error "This script must be run as Administrator."
    Exit 1
}

Write-Host -Foreground Red "# ====================================================================="
Write-Host -Foreground Yellow "MAKE SURE YOU UNPLUG THE EXTERNAL SSD OR USB THAT CONTAINS THESE FILES!!!"
Write-Host -Foreground Red "# ====================================================================="
Read-Host "Press enter to continue..."


Write-Host "Starting system configuration..." -Foreground Cyan

# =========================
# Create Partition D: (60%)
# =========================


Write-Host "Evaluating disk layout..." -Foreground Cyan

$diskNumber = 0
$disk = Get-Disk -Number $diskNumber

$diskSizeBytes = $disk.Size
$desiredCSizeBytes = [math]::Floor($diskSizeBytes * 0.40)

# Get C: partition
$cPartition = Get-Partition -DiskNumber $diskNumber | Where-Object DriveLetter -eq 'C'

If (-not $cPartition) {
    Write-Error "C: partition not found. Aborting."
    Exit 1
}

# Determine supported shrink size
$supported = Get-PartitionSupportedSize -DiskNumber $diskNumber -PartitionNumber $cPartition.PartitionNumber

If ($desiredCSizeBytes -lt $supported.SizeMin) {
    Write-Error "Cannot shrink C: to 40%. Minimum supported size is $($supported.SizeMin / 1GB) GB."
    Exit 1
}

Write-Host "Shrinking C: to 40% of disk..." -Foreground Yellow

Resize-Partition -DiskNumber $diskNumber -PartitionNumber $cPartition.PartitionNumber -Size $desiredCSizeBytes

# Check if D: already exists
$existingD = Get-Partition -DiskNumber $diskNumber -ErrorAction SilentlyContinue |
    Where-Object DriveLetter -eq 'D'

if (-not $existingD) {

    Write-Host "Creating D: partition from remaining space..." -Foreground Yellow

    $newPartition = New-Partition -DiskNumber $diskNumber -UseMaximumSize -DriveLetter 'D'

    Format-Volume -Partition $newPartition -FileSystem NTFS -NewFileSystemLabel "New Volume" -Confirm:$false

    Write-Host -Foreground Green "[x] Parition D: has been created."
}
else {
    Write-Host "D: already exists. Skipping partition creation." -Foreground Green
}

# ===============================
# Create Folders in new partition
# ===============================

Write-Host -Foreground Yellow "[x] Creating folders in D:\"

$folders = @(
    "D:\Profiles",
    "D:\Outlook",
    "D:\Temp"
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -Path $folder -ItemType Directory -Force | Out-Null
        Write-Host -Foreground Green "[x] $folder created"
    } else {
        Write-Host "$folder already exists"
    }
}

# =======================
# Create Local Admin User
# =======================

$userName = "Soporte"

If (-not (Get-LocalUser -Name $userName -ErrorAction SilentlyContinue)) {

    Write-Host "[ ] Creating local admin user: $userName" -Foreground Yellow

    $newSoportePassword = Read-Host -AsSecureString "Enter new password:"
    
    New-LocalUser -Name $userName -Password $newSoportePassword

    Add-LocalGroupMember -Group "Administrators" -Member $userName

    Write-Host -Foreground Green "[x] $userName created."
} else {
    Write-Host "User $userName already exists. Skipping." -Foreground Red
}


# ===========================
# Redirect Profiles Directory
# ===========================

$profileListKey = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList"

Write-Host "Setting ProfilesDirectory to D:\Profiles" -Foreground Yellow

Set-ItemProperty -Path $profileListKey -Name "ProfilesDirectory" -Value "D:\Profiles"

Write-Host -Foreground Green "[x] ProfilesDirectory has been set to D:\Profiles."


# ================
# Install software
# ================

Write-Host -Foreground Yellow "[ ] Installing Java silently."

Try {
  Start-Process -FilePath "JavaOCI\jre-8u341-windows-i586.exe" -Argument "/s"
  Write-Host -Foreground Green "[x] Java has been installed."
}
Catch {
  Write-Error "Something went wrong with the Java Installation."
}

Write-Host -Foreground Yellow "[ ] Installing Windows Runtime silently."
Try {
  Start-Process -FilePath "windowsdesktop-runtime-8.0.26-win-x64.exe" -Argument "/s"
  Write-Host -Foreground Green "[x] Windows Runtime installed."
}
Catch {
  Write-Error "Something went wrong with the Desktop Runtime installation."
}

# =========================================
# Disable admin account and change password
# =========================================

$newAdminPassword = Read-Host -AsSecureString "Enter the new password for Administrator account:"
Write-Host -Foreground Yellow "Changing Administrator password and disabling account..."
Set-LocalUser -Name Administrator -Password $newAdminPassword
Disable-LocalUser -Name Administrator
Write-Host -Foreground Green "[x] Local Administrator password changed and account disabled."

# ===============================================
# Getting printer drivers and installing printers
# ===============================================

Write-Host -Foreground Yellow "Installing HP color printer."
Try {
  Add-PrinterPort -Name "192.168.17.41" -PrinterHostAddress "192.168.17.41"
  Start-Process -FilePath ".\HP-Driver-UPDPCL6\Install.exe" -ArgumentList "/q /h /dst /sm192.168.17.41 /nHPColor"
  Start-Sleep -seconds 10
  Rename-Printer -Name "HPColor" -NewName "Central HP Color"
  Write-Host -Foreground Green "[x] Printer has been installed."
} Catch {
  Write-Error "Unable to add printer."
}

Write-Host -Foreground Yellow "Installing Ricoh printer."
Try  {
  Write-Host -Foreground Yellow "Installing driver."
  pnputil -i -a ".\ricoh-driver\disk1\MP_350__.inf"
  Write-Host -Foreground Yellow "Adding driver."
  Add-PrinterDriver "Gestetner IM 430 PCL 6"
  Write-Host -Foreground Yellow "Adding printer."
  Add-PrinterPort -Name "192.168.17.28" -PrinterHostAddress "192.168.17.28"
  Add-Printer -Name "Ricoh Printer" -DriverName "Gestetner IM 430 PCL 6" -PortName "192.168.17.28"
  Write-Host -Foreground Green "[x] Driver installed."
}
Catch {
  Write-Error "Unable to add Ricoh printer driver."
}

# ==============
# Installing VPN 
# ==============

Write-Host -Foreground Yellow "Installing VPN."
Try {
  Write-Host -Foreground "Installing VPN."
  Start-Process -FilePath "VPN\ConnectTunnel_x64-12.5.0.221.exe" -ArgumentList "/s"
  Write-Host -Foreground Green "[x] VPN has been installed."
}
Catch {
  Write-Error "Unable to install VPN."
}

# ==========================
# Installing EndpointCentral 
# ==========================

Write-Host -Foreground Yellow "Installing EPC."
Try {
  Write-Host -Foreground "Installing EPC."
  cmd.exe /c 'start /wait msiexec /i EndpointCentral\UEMSAgent.msi TRANSFORMS="EndpointCentral\UEMSAgent.mst" ENABLESILENT=yes REBOOT=ReallySuppress INSTALLSOURCE=Manual SERVER_ROOT_CRT="EndpointCentral\DMRootCA-Server.crt" DS_ROOT_CRT="EndpointCentral\DMRootCA.crt" /lv Agentinstalllog.txt' 
  Write-Host -Foreground Green "[x] EPC has been installed."
}
Catch {
  Write-Error "Unable to install EPC. Please install it manually."
}

# ==========================
# Installing Outlook Classic 
# ==========================

Write-Host -Foreground Yellow "Installing Outlook classic."
Try {
  Start-Process -FilePath ".\OfficeSetup.exe"
  Write-Host -Foreground Green "[x] Outlook Classic has been installed."
}
Catch {
  Write-Error "Unable to install Outlook Classic. Reboot before you try to install it again."
}

# =======================
# Installing Dell Command 
# =======================

Try {
  Write-Host -Foreground Yellow "Installing Dell Command"
  Start-Process -FilePath "Dell-Command-Update-Windows-Universal.exe" 
}
Catch {
  Write-Error "Unable to install Dell Command. Try installing the app specific for your hardware."
}

# ============
# Enabling WoL 
# ============

Try {
  Write-Host -Foreground Yellow "Enabling WoL."
  Get-NetAdapter -Name "Ethernet*"  | Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled -WakeOnPattern Enabled
  Write-Host -Foreground Green "[x] WoL enabled on all Ethernet Ports."
}
Catch {
  Write-Error "Unable to set up WoL. Please check the name of the NetAdapters or enable manually."
}

# ==========================================
# Setting computer name and adding to domain
# ==========================================

$answer = Read-Host "Add computer to domain? (y/n)"
if $answer -eq "y" {
  Write-Host -Foreground Yellow "Initiating computer name change."
  $computerName = Read-Host "Enter new computer name:"
  Add-Computer -DOmainName "aiig.com" -NewName $computerName
  Write-Host -Foreground Green "[x] computer name has been changed. Reboot."
} 
Else {
  Write-Host -Foreground Yellow "Skipping domain join."
  Continue
}

# ==========
# Completion
# ==========

Write-Host "Configuration completed successfully." -Foreground Green
Write-Host "A reboot is recommended before creating new user profiles." -Foreground Yellow 
