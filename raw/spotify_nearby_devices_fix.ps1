# Allow mDNS (most important)
New-NetFirewallRule `
  -DisplayName "ALLOW Spotify mDNS Out" `
  -Direction Outbound `
  -Program "$env:APPDATA\Spotify\Spotify.exe" `
  -Protocol UDP `
  -RemotePort 5353 `
  -RemoteAddress 224.0.0.251 `
  -Action Allow `
  -Profile Any

# Allow SSDP (sometimes needed)
New-NetFirewallRule `
  -DisplayName "ALLOW Spotify SSDP Out" `
  -Direction Outbound `
  -Program "$env:APPDATA\Spotify\Spotify.exe" `
  -Protocol UDP `
  -RemotePort 1900 `
  -RemoteAddress 239.255.255.250 `
  -Action Allow `
  -Profile Any

# Allow local subnet high UDP (device handshake)
New-NetFirewallRule `
  -DisplayName "ALLOW Spotify Local UDP Out" `
  -Direction Outbound `
  -Program "$env:APPDATA\Spotify\Spotify.exe" `
  -Protocol UDP `
  -RemotePort 1024-65535 `
  -RemoteAddress LocalSubnet `
  -Action Allow `
  -Profile Any