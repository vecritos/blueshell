# Define Edge executable path
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"

# Check if Edge executable exists
if (-Not (Test-Path $edgePath)) {
    Write-Error "Microsoft Edge executable not found at $edgePath"
    exit
}

# Remove existing firewall rules for Edge (optional, be careful)
Get-NetFirewallApplicationFilter -Program $edgePath | Remove-NetFirewallRule

# Block all outgoing connections for Edge by default
New-NetFirewallRule -DisplayName "Block all Outbound for Edge" `
    -Direction Outbound `
    -Program $edgePath `
    -Action Block `
    -Profile Any `
    -Description "Block all outbound connections for Edge by default"

# Allow Edge outbound HTTP (port 80)
New-NetFirewallRule -DisplayName "Allow Edge HTTP Outbound" `
    -Direction Outbound `
    -Program $edgePath `
    -Action Allow `
    -Protocol TCP `
    -LocalPort Any `
    -RemotePort 80 `
    -Profile Any `
    -Description "Allow HTTP outbound traffic for Edge"

# Allow Edge outbound HTTPS (port 443)
New-NetFirewallRule -DisplayName "Allow Edge HTTPS Outbound" `
    -Direction Outbound `
    -Program $edgePath `
    -Action Allow `
    -Protocol TCP `
    -LocalPort Any `
    -RemotePort 443 `
    -Profile Any `
    -Description "Allow HTTPS outbound traffic for Edge"