New-NetFirewallRule `
  -DisplayName "ALLOW Outbound Established" `
  -Direction Outbound `
  -Action Allow `
  -Profile Any `
  -Enabled True `
  -EdgeTraversalPolicy Allow

New-NetFirewallRule `
  -DisplayName "ALLOW Loopback Out" `
  -Direction Outbound `
  -LocalAddress 127.0.0.1 `
  -RemoteAddress 127.0.0.1 `
  -Action Allow `
  -Profile Any

New-NetFirewallRule `
  -DisplayName "ALLOW Loopback In" `
  -Direction Inbound `
  -LocalAddress 127.0.0.1 `
  -RemoteAddress 127.0.0.1 `
  -Action Allow `
  -Profile Any

# specific to store version of spotify
#New-NetFirewallRule `
#  -DisplayName "ALLOW Spotify UWP Out" `
#  -Direction Outbound `
#  -Package "SpotifyAB.SpotifyMusic_zpdnekdrzrea0" `
#  -Action Allow