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
$supported = Get-PartitionSupportedSize `
    -DiskNumber $diskNumber `
    -PartitionNumber $cPartition.PartitionNumber

If ($desiredCSizeBytes -lt $supported.SizeMin) {
    Write-Error "Cannot shrink C: to 40%. Minimum supported size is $($supported.SizeMin / 1GB) GB."
    Exit 1
}

Write-Host "Shrinking C: to 40% of disk..." -Foreground Yellow

Resize-Partition `
    -DiskNumber $diskNumber `
    -PartitionNumber $cPartition.PartitionNumber `
    -Size $desiredCSizeBytes



# Check if D: already exists
$existingD = Get-Partition -DiskNumber $diskNumber -ErrorAction SilentlyContinue |
    Where-Object DriveLetter -eq 'D'

if (-not $existingD) {

    Write-Host "Creating D: partition from remaining space..." -Foreground Yellow

    $newPartition = New-Partition `
        -DiskNumber $diskNumber `
        -UseMaximumSize `
        -DriveLetter 'D'

    Format-Volume `
        -Partition $newPartition `
        -FileSystem NTFS `
        -NewFileSystemLabel "New Volume" `
        -Confirm:$false
}
else {
    Write-Host "D: already exists. Skipping partition creation." -Foreground Green
}

# ===============================
# Create Folders in new partition
# ===============================

Write-Host -Foreground Yellow "Creating folders in D:\"

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
        Write-Host "[ ] $folder already exists"
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

# =================================
# Disable Windows Defender Firewall
# =================================
Write-Host -Foreground Yellow "Checking if Firewall is enabled..."
Get-NetFirewallProfile | Select Name,Enabled 

Write-Host -Foreground Yellow "Disabling Firewall..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled False


# =========================================
# Disable admin account and change password
# =========================================

$newAdminPassword = Read-Host -AsSecureString "Enter the new password for Administrator account:"
Write-Host -Foreground Yellow "Changing Administrator password and disabling account..."
Set-LocalUser -Name Administator -Password $newAdminPassword
Disable-LocalUser -Name Administrator
Write-Host -Foreground Green "Admin password changed and account disabled."

# ===============================================
# Getting printer drivers and installing printers
# ===============================================
Write-Host -Foreground Yellow "Initiating computer name change."
$computerName = Read-Host "Enter new computer name:"
Add-Computer -DOmainName "aiig.com" -NewName $computerName
Write-Host -Foreground Green "[x] computer name has been changed. Reboot."

# ==========
# Completion
# ==========

Write-Host "Configuration completed successfully." -Foreground Cyan
Write-Host "A reboot is recommended before creating new user profiles." -Foreground Magenta
