# -----------------------------
# Windows-native IKEv2 VPN Firewall Fix
# -----------------------------
# Allows only IKEv2/IPSec ports and ESP for VPN connections

# 1️ Allow IKEv2 / IPSec ports (UDP 500, 4500)
$Ports = @(500, 4500)
foreach ($port in $Ports) {
    # Outbound
    New-NetFirewallRule -DisplayName "IKEv2 UDP $port Outbound" -Direction Outbound -Protocol UDP -LocalPort $port -Action Allow -Profile Any -ErrorAction SilentlyContinue
    # Inbound
    New-NetFirewallRule -DisplayName "IKEv2 UDP $port Inbound" -Direction Inbound -Protocol UDP -LocalPort $port -Action Allow -Profile Any -ErrorAction SilentlyContinue
}

# 2️ Allow ESP (IP protocol 50)
New-NetFirewallRule -DisplayName "IKEv2 ESP Outbound" -Direction Outbound -Protocol 50 -Action Allow -Profile Any -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "IKEv2 ESP Inbound" -Direction Inbound -Protocol 50 -Action Allow -Profile Any -ErrorAction SilentlyContinue

# 3️ Enable firewall logging (optional, for troubleshooting)
Set-NetFirewallProfile -Profile Domain,Private,Public -LogBlocked True -LogFileName "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"

Write-Host "✅ IKEv2 firewall rules applied. Reconnect your Windows VPN!" -ForegroundColor Green