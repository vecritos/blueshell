# ================================
# Spotify Firewall Lockdown Script
# Run as Administrator
# ================================

Write-Host "=== Spotify Firewall Setup ===" -ForegroundColor Cyan

# --- Locate Spotify executables ---
$spotifyPaths = @()

$pathsToSearch = @(
    "$env:APPDATA\Spotify",
    "$env:LOCALAPPDATA\Microsoft\WindowsApps"
)

foreach ($base in $pathsToSearch) {
    if (Test-Path $base) {
        $found = Get-ChildItem $base -Recurse -Filter spotify.exe -ErrorAction SilentlyContinue |
            Select-Object -ExpandProperty FullName -Unique
        $spotifyPaths += $found
    }
}

$spotifyPaths = $spotifyPaths | Sort-Object -Unique

if (-not $spotifyPaths) {
    Write-Host "Spotify.exe not found. Launch Spotify once and rerun." -ForegroundColor Red
    exit 1
}

Write-Host "Found Spotify installs:"
$spotifyPaths | ForEach-Object { Write-Host "  $_" }

# --- DNS allow (safe if already exists) ---
Write-Host "`nEnsuring DNS rules exist..." -ForegroundColor Green

New-NetFirewallRule -DisplayName "ALLOW DNS UDP Out" `
    -Direction Outbound -Protocol UDP -RemotePort 53 `
    -Action Allow -Profile Any -ErrorAction SilentlyContinue

New-NetFirewallRule -DisplayName "ALLOW DNS TCP Out" `
    -Direction Outbound -Protocol TCP -RemotePort 53 `
    -Action Allow -Profile Any -ErrorAction SilentlyContinue

# --- Create rules per Spotify binary ---
foreach ($path in $spotifyPaths) {

    Write-Host "`nCreating rules for: $path" -ForegroundColor Green

    # HTTPS streaming
    New-NetFirewallRule -DisplayName "ALLOW Spotify HTTPS Out ($path)" `
        -Direction Outbound `
        -Program $path `
        -Protocol TCP `
        -RemotePort 443 `
        -Action Allow `
        -Profile Any `
        -ErrorAction SilentlyContinue

    # Optional legacy port (rare but harmless)
    New-NetFirewallRule -DisplayName "ALLOW Spotify TCP 4070 Out ($path)" `
        -Direction Outbound `
        -Program $path `
        -Protocol TCP `
        -RemotePort 4070 `
        -Action Allow `
        -Profile Any `
        -ErrorAction SilentlyContinue

    # Optional high UDP (local features, device discovery)
    New-NetFirewallRule -DisplayName "ALLOW Spotify UDP High Out ($path)" `
        -Direction Outbound `
        -Program $path `
        -Protocol UDP `
        -RemotePort 50000-65535 `
        -Action Allow `
        -Profile Any `
        -ErrorAction SilentlyContinue
}

Write-Host "`n=== Rule Summary ===" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object DisplayName -like "*Spotify*" |
    Select-Object DisplayName, Enabled, Direction

Write-Host "`nDone. Test Spotify playback." -ForegroundColor Cyan