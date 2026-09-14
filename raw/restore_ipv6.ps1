Write-Host "=== Resetting Windows Firewall to defaults ==="
netsh advfirewall reset

Write-Host "=== Re-enabling IPv6 on all adapters ==="
Get-NetAdapter | Where-Object {$_.Status -ne "Disabled"} | ForEach-Object {
    try {
        Set-NetAdapterBinding -Name $_.Name -ComponentID ms_tcpip6 -Enabled $true -ErrorAction Stop
        Write-Host "IPv6 enabled on $($_.Name)"
    } catch {
        Write-Host "Could not modify $($_.Name)"
    }
}

Write-Host "=== Restarting IPsec services ==="
Restart-Service PolicyAgent -Force -ErrorAction SilentlyContinue
Restart-Service IKEEXT -Force -ErrorAction SilentlyContinue

Write-Host "=== Done. REBOOT recommended ==="