# ================================
# Discord Firewall Lockdown Script
# Run as Administrator
# ================================

Write-Host "=== Discord Firewall Setup ===" -ForegroundColor Cyan

# --- CONFIG ---
$BlockAllOutbound = $true   # <-- set to $false if you DON'T want global block

# Resolve Discord executable(s)
$discordPaths = Get-ChildItem "$env:LOCALAPPDATA\Discord" -Recurse -Filter Discord.exe -ErrorAction SilentlyContinue |
    Select-Object -ExpandProperty FullName -Unique

if (-not $discordPaths) {
    Write-Host "Discord.exe not found. Start Discord once and rerun." -ForegroundColor Red
    exit 1
}

Write-Host "Found Discord installs:"
$discordPaths | ForEach-Object { Write-Host "  $_" }

# --- OPTIONAL: Set outbound default to block ---
if ($BlockAllOutbound) {
    Write-Host "`nSetting outbound policy to BLOCK (Domain/Private/Public)..." -ForegroundColor Yellow
    Set-NetFirewallProfile -Profile Domain,Private,Public -DefaultOutboundAction Block
}

# --- Allow DNS (required for everything) ---
Write-Host "`nCreating DNS allow rules..." -ForegroundColor Green

New-NetFirewallRule -DisplayName "ALLOW DNS UDP Out" `
    -Direction Outbound -Protocol UDP -RemotePort 53 `
    -Action Allow -Profile Any -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "ALLOW DNS TCP Out" `
    -Direction Outbound -Protocol TCP -RemotePort 53 `
    -Action Allow -Profile Any -ErrorAction SilentlyContinue

# --- Create rules per Discord binary ---
foreach ($path in $discordPaths) {

    Write-Host "`nCreating rules for: $path" -ForegroundColor Green

    # HTTPS (login, messages, CDN)
    New-NetFirewallRule -DisplayName "ALLOW Discord HTTPS Out ($path)" `
        -Direction Outbound `
        -Program $path `
        -Protocol TCP `
        -RemotePort 443 `
        -Action Allow `
        -Profile Any `
        -ErrorAction SilentlyContinue

    # Voice / WebRTC
    New-NetFirewallRule -DisplayName "ALLOW Discord Voice Out ($path)" `
        -Direction Outbound `
        -Program $path `
        -Protocol UDP `
        -RemotePort 3478-3481,50000-65535 `
        -Action Allow `
        -Profile Any `
        -ErrorAction SilentlyContinue
}

Write-Host "`n=== Rule Summary ===" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object DisplayName -like "*Discord*" |
    Select-Object DisplayName, Enabled, Direction

Write-Host "`nDone. Test Discord voice + messaging." -ForegroundColor Cyan