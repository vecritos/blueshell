# IKEv2 UDP ports
New-NetFirewallRule -DisplayName "IKEv2 UDP 500 Out" -Direction Outbound -Protocol UDP -RemotePort 500 -Action Allow
New-NetFirewallRule -DisplayName "IKEv2 UDP 4500 Out" -Direction Outbound -Protocol UDP -RemotePort 4500 -Action Allow

# ESP protocol
New-NetFirewallRule -DisplayName "IKEv2 ESP Out" -Direction Outbound -Protocol 50 -Action Allow