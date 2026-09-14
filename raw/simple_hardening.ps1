# Disable noisy discovery
Disable-NetFirewallRule -DisplayGroup "Network Discovery"

# Disable SMB sharing if unused
Disable-NetFirewallRule -DisplayGroup "File and Printer Sharing"

# Disable remote assistance
Get-NetFirewallRule -DisplayGroup "Remote Assistance" | Disable-NetFirewallRule

# Optional: delivery optimization
Get-NetFirewallRule -DisplayName "*Delivery Optimization*" | Disable-NetFirewallRule