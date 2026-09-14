# ============================================
# NUCLEAR Self-Healing Firewall Baseline
# Riot + League + Discord (resilient version)
# ============================================

Write-Host "=== Riot/League firewall repair starting ===" -ForegroundColor Cyan

# ---------- Helper: ensure rule exists ----------
function Ensure-FirewallRule {
    param(
        [string]$Name,
        [hashtable]$Params
    )

    $existing = Get-NetFirewallRule -DisplayName $Name -ErrorAction SilentlyContinue
    if (-not $existing) {
        Write-Host "Creating rule: $Name" -ForegroundColor Yellow
        New-NetFirewallRule @Params -ErrorAction SilentlyContinue | Out-Null
    } else {
        Write-Host "Rule OK: $Name" -ForegroundColor DarkGreen
    }
}

# ---------- Discover Riot executables ----------
$RiotRoot = "C:\Riot Games"
$RiotExes = @()

if (Test-Path $RiotRoot) {
    $RiotExes = Get-ChildItem $RiotRoot -Recurse -Filter *.exe -ErrorAction SilentlyContinue |
        Where-Object {
            $_.FullName -match "RiotClient|LeagueClient" -or
            $_.FullName -match "\\Game\\League of Legends.exe$"
        } |
        Select-Object -ExpandProperty FullName -Unique
}

# ---------- Discover Discord dynamically ----------
$DiscordExe = Get-ChildItem "$env:LOCALAPPDATA\Discord" -Recurse -Filter Discord.exe -ErrorAction SilentlyContinue |
Select-Object -First 1 -ExpandProperty FullName

# ============================================
# Riot + League rules
# ============================================

foreach ($exe in $RiotExes) {

    $safeName = ($exe -replace '[^a-zA-Z0-9]', '_')

    # TCP web/auth
    Ensure-FirewallRule -Name "RiotAuto_TCP_$safeName" -Params @{
        DisplayName = "RiotAuto_TCP_$safeName"
        Direction   = "Outbound"
        Program     = $exe
        Protocol    = "TCP"
        RemotePort  = "80,443"
        Action      = "Allow"
    }

    # UDP gameplay ports (safe for non-game exes too)
    Ensure-FirewallRule -Name "RiotAuto_UDP_$safeName" -Params @{
        DisplayName = "RiotAuto_UDP_$safeName"
        Direction   = "Outbound"
        Program     = $exe
        Protocol    = "UDP"
        RemotePort  = "5000-5500,8088"
        Action      = "Allow"
    }
}

# ============================================
# Discord rules (voice works)
# ============================================

if ($DiscordExe -and (Test-Path $DiscordExe)) {

    Ensure-FirewallRule -Name "Discord Outbound Allow" -Params @{
        DisplayName = "Discord Outbound Allow"
        Direction   = "Outbound"
        Program     = $DiscordExe
        Action      = "Allow"
    }

    Ensure-FirewallRule -Name "Discord Inbound Allow" -Params @{
        DisplayName = "Discord Inbound Allow"
        Direction   = "Inbound"
        Program     = $DiscordExe
        Protocol    = "UDP"
        Action      = "Allow"
    }

    Write-Host "Discord detected." -ForegroundColor DarkGreen
}
else {
    Write-Host "Discord not found (skipped)." -ForegroundColor DarkYellow
}

# ============================================
# Enable blocked logging
# ============================================

Set-NetFirewallProfile -LogBlocked True -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Firewall baseline enforced ===" -ForegroundColor Green
Write-Host "If Riot ever changes binaries, rerun this script." -ForegroundColor Cyan