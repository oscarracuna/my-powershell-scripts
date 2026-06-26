param(
    [switch]$NoPartition,
    [switch]$NoLocalAdmin,
    [switch]$NoProfilesRedirect,
    [switch]$NoJava,
    [switch]$NoRuntime,
    [switch]$NoPrinters,
    [switch]$NoVPN,
    [switch]$NoBitdefender,
    [switch]$NoDellCommand,
    [switch]$NoWOL,
    [switch]$NoDomainJoin,
    [switch]$NoAdminDisable,
    [switch]$Office32
)

# =======
# Logging
# =======
Start-Transcript -Path "C:\Temp\deploy.log" -Append -ErrorAction SilentlyContinue

function Write-Log {
    param([string]$Message)
    Write-Host "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $Message"
}

Write-Log "===== STARTING CONFIGURATION ====="

Write-Host -Foreground Green "Disabling Powershell history."
Set-PSReadLineOption -HistorySaveStyle SaveNothing

# =================
# Profiles Redirect
# =================
function Set-ProfilesRedirect {
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\ProfileList" -Name ProfilesDirectory -Value "D:\Profiles"
}

# ==============
# Disk Partition
# ==============
function Set-Partition {
    Write-Log "Evaluating disk layout..."

    $disk = Get-Disk -Number 0
    $desiredCSize = [math]::Floor($disk.Size * 0.40)

    $cPartition = Get-Partition | Where-Object DriveLetter -eq 'C'
    if (-not $cPartition) { throw "C: not found" }

    $supported = Get-PartitionSupportedSize -PartitionNumber $cPartition.PartitionNumber -DiskNumber 0

    if ($desiredCSize -lt $supported.SizeMin) {
        throw "Shrink not supported"
    }

    Resize-Partition -PartitionNumber $cPartition.PartitionNumber -DiskNumber 0 -Size $desiredCSize

    if (-not (Get-Partition | Where DriveLetter -eq 'D')) {
        $new = New-Partition -DiskNumber 0 -UseMaximumSize -DriveLetter 'D'
        Format-Volume -Partition $new -FileSystem NTFS -Confirm:$false
        Write-Log "D: created"
    }
    
    $folders = "D:\Profiles","D:\Outlook","D:\Temp"
    foreach ($folder in $folders) {
        if (-not (Test-Path $folder)) {
            New-Item $folder -ItemType Directory | Out-Null
            Write-Log "$folder created"
        }
    }
    Set-ProfilesRedirect
}

if (-not $NoPartition) {
    try { Set-Partition } catch { Write-Log $_ }
} else {
    Write-Log "Skipping partitioning"
}

# =======
# Soporte
# =======
function Set-LocalAdmin {
    $user = "Soporte"

    if (-not (Get-LocalUser $user -ErrorAction SilentlyContinue)) {
        $pwd = Read-Host -AsSecureString "Password for $user"
        New-LocalUser $user -Password $pwd
        Add-LocalGroupMember Administrators $user
        Write-Log "$user created"
    }
}

if (-not $NoLocalAdmin) { Set-LocalAdmin }

# =============
# Admin disable
# =============
if (-not $NoAdminDisable) {
    $pwd = Read-Host -AsSecureString "Admin password"
    Set-LocalUser Administrator -Password $pwd
    Disable-LocalUser Administrator
}

# ================
# Install Function
# ================
function Install-App {
    param($Path, $Argos, $Name)

    try {
        Write-Host -Foreground Green "Installing $Name."
        Start-Process $Path -ArgumentList $Argos -Wait
        Write-Log "$Name installed"
    } catch {
        Write-Log "$Name FAILED"
    }
}

# ========
# Software
# ========
if (-not $NoJava) {
    Install-App "JavaOCI\jre-8u341-windows-i586.exe" "/s" "Java"
}

if (-not $NoRuntime) {
    Install-App "windowsdesktop-runtime-8.0.26-win-x64.exe" "/quiet" "Runtime"
}

if (-not $NoVPN) {
    Install-App "ConnectTunnel_x64.exe" "/silent" "VPN"
}

if (-not $NoBitdefender) {
    Install-App "Bitdefender\epskit_x64.exe" "/s" "Bitdefender"
}

if (-not $NoDellCommand) {
    Install-App "Dell-Command-Update-Windows-Universal.exe" "/s" "Dell Command"
}

if (-not $Office32) {
  Install-App "OfficeSetup.exe" "/s" "Office 32 bits"
}

if ($Office32) {
  Install-App "OfficeSetup32bits.exe" "Office 64 bits"
}
# ========
# Printers
# ========
function Install-Printers {

    Add-PrinterPort -Name "192.168.17.41" -PrinterHostAddress "192.168.17.41"
    Start-Process ".\HP-Driver-UPDPCL6\Install.exe" "/q /h /dst /sm192.168.17.41 /nCentralHPColor"

    pnputil -i -a ".\ricoh-driver\disk1\MP_350__.inf"
    Add-PrinterDriver "Gestetner IM 430 PCL 6"

    Add-PrinterPort -Name "192.168.17.28" -PrinterHostAddress "192.168.17.28"
    Add-Printer -Name "Ricoh Printer" -DriverName "Gestetner IM 430 PCL 6" -PortName "192.168.17.28"
}

if (-not $NoPrinters) {
    try { Install-Printers } catch { Write-Log "Printer install failed" }
}

# ===========
# Wake on LAN
# ===========
if (-not $NoWOL) {
    Write-Host -Foreground Green "Enabling WakeOnMagicPacket and WakeOnPattern on all Ethernet interfaces."
    Get-NetAdapter -Name "Ethernet*" | Set-NetAdapterPowerManagement -WakeOnMagicPacket Enabled
    Get-NetAdapter -Name "Ethernet*" | Set-NetAdapterPowerManagement -WakeOnPattern Enabled
}

# ===========
# Domain Join
# ===========
if (-not $NoDomainJoin) {
      $computerName = Read-Host "New computer name"
      Add-Computer -DomainName "aiig.com" -NewName $computerName
}


Write-Log "===== COMPLETED ====="
Stop-Transcript
