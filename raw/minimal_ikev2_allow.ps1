# ===== VARIABLES =====
$profiles = @("Public")   # change if needed

# ===== CORE IPsec / IKEv2 TRAFFIC =====

# UDP 500 (IKE)
New-NetFirewallRule -DisplayName "VPN IKEv2 UDP 500 OUT" `
  -Direction Outbound -Protocol UDP -RemotePort 500 `
  -Action Allow -Profile $profiles

New-NetFirewallRule -DisplayName "VPN IKEv2 UDP 500 IN" `
  -Direction Inbound -Protocol UDP -LocalPort 500 `
  -Action Allow -Profile $profiles

# UDP 4500 (NAT-T)
New-NetFirewallRule -DisplayName "VPN IKEv2 UDP 4500 OUT" `
  -Direction Outbound -Protocol UDP -RemotePort 4500 `
  -Action Allow -Profile $profiles

New-NetFirewallRule -DisplayName "VPN IKEv2 UDP 4500 IN" `
  -Direction Inbound -Protocol UDP -LocalPort 4500 `
  -Action Allow -Profile $profiles

# ESP (IP protocol 50)
New-NetFirewallRule -DisplayName "VPN IKEv2 ESP OUT" `
  -Direction Outbound -Protocol 50 `
  -Action Allow -Profile $profiles

New-NetFirewallRule -DisplayName "VPN IKEv2 ESP IN" `
  -Direction Inbound -Protocol 50 `
  -Action Allow -Profile $profiles

# ===== CRITICAL WINDOWS SERVICES =====

# Allow svchost for IPsec
New-NetFirewallRule -DisplayName "VPN svchost OUT" `
  -Direction Outbound -Program "%SystemRoot%\System32\svchost.exe" `
  -Action Allow -Profile $profiles

New-NetFirewallRule -DisplayName "VPN svchost IN" `
  -Direction Inbound -Program "%SystemRoot%\System32\svchost.exe" `
  -Action Allow -Profile $profiles

# ===== DNS THROUGH VPN =====
New-NetFirewallRule -DisplayName "VPN DNS OUT" `
  -Direction Outbound -Protocol UDP -RemotePort 53 `
  -Action Allow -Profile $profiles