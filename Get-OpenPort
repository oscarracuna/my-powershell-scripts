Function isItOpen {
    $ip = Read-Host "Enter IP" 
    
    $ports = @("20","21","22","23","25","80","88","135","443","464","465","593","8080")

    ForEach ($Port in $Ports) {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        try { 
            $abr = $tcpClient.ConnectAsync($ip, $Port).Wait(800)
            if ($abr -eq $True ) {
                Write-Host "[*] $Port open"
            } else {
                continue
            }  
        } finally {
            $tcpClient.Close()
        }
    }
}
isItOpen
