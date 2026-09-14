# ===============================
# Minimal Firewall Rules
# Riot + League + Discord
# ===============================

Write-Host "Applying firewall rules..." -ForegroundColor Cyan

# ---- Paths (edit if your install differs) ----
$RiotUx   = "C:\Riot Games\Riot Client\RiotClientUx.exe"
$LeagueEx = "C:\Riot Games\League of Legends\LeagueClient.exe"
$Discord  = "$env:LOCALAPPDATA\Discord\app-*\Discord.exe"

# ===============================
# Riot Client (login/patch)
# ===============================
New-NetFirewallRule -DisplayName "Riot Client TCP Out" `
-Direction Outbound `
-Program $RiotUx `
-Protocol TCP `
-RemotePort 80,443 `
-Action Allow -ErrorAction SilentlyContinue

# ===============================
# League Game Traffic (NO voice)
# ===============================
New-NetFirewallRule -DisplayName "League Game UDP Out" `
-Direction Outbound `
-Program $LeagueEx `
-Protocol UDP `
-RemotePort 5000-5500,8088 `
-Action Allow -ErrorAction SilentlyContinue

# HTTPS fallback for League client
New-NetFirewallRule -DisplayName "League Client TCP Out" `
-Direction Outbound `
-Program $LeagueEx `
-Protocol TCP `
-RemotePort 443 `
-Action Allow -ErrorAction SilentlyContinue

# ===============================
# Discord (voice + chat)
# ===============================
New-NetFirewallRule -DisplayName "Discord Outbound Allow" `
-Direction Outbound `
-Program $Discord `
-Action Allow -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "Discord Inbound Allow" `
-Direction Inbound `
-Program $Discord `
-Protocol UDP `
-Action Allow -ErrorAction SilentlyContinue

Write-Host "Done. If something fails, check firewall logs." -ForegroundColor Green