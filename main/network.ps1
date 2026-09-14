# ==========================================
# Blueshellctl Network & Firewall Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
$Script:NetworkStateFile = Join-Path $Script:BlueshellctlRoot "network.json"

function Initialize-NetworkModule {
    if (-not (Test-Path $Script:BlueshellctlRoot)) {
        New-Item -ItemType Directory -Path $Script:BlueshellctlRoot -Force | Out-Null
    }
    if (-not (Test-Path $Script:NetworkStateFile)) {
        $state = @{ hardened = $false; timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss") }
        $state | ConvertTo-Json | Set-Content -Path $Script:NetworkStateFile -Encoding UTF8
    }
}

function Get-NetworkState {
    Initialize-NetworkModule
    Get-Content $Script:NetworkStateFile -Raw | ConvertFrom-Json
}

function Set-NetworkState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:NetworkStateFile -Encoding UTF8
}

function Invoke-NetworkHarden {
    Write-Host "Applying firewall and network hardening..." -ForegroundColor Cyan

    # Reset firewall to default deny
    Write-Host "Resetting Windows Firewall to default deny inbound, allow outbound..."
    New-NetFirewallRule -DisplayName "Block All Inbound" -Direction Inbound -Action Block -Enabled True
    Set-NetFirewallProfile -Profile Domain,Public,Private -DefaultInboundAction Block -DefaultOutboundAction Allow

    # Allow only essential outbound ports (e.g., HTTPS)
    Write-Host "Allowing essential outbound ports..."
    New-NetFirewallRule -DisplayName "Allow Outbound HTTPS" -Direction Outbound -Action Allow -Protocol TCP -LocalPort Any -RemotePort 443

    # Optional: restrict DNS to specific servers
    $dnsServers = @("8.8.8.8","1.1.1.1")
    foreach ($adapter in Get-DnsClientServerAddress | Where-Object {$_.AddressFamily -eq "IPv4"}) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.InterfaceIndex -ServerAddresses $dnsServers
    }

    # Update state
    $state = Get-NetworkState
    $state.hardened = $true
    $state.timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-NetworkState -State $state

    Write-Host "Network hardening complete." -ForegroundColor Green
}

function Disable-NetworkAdapters {
    Write-Host "Disabling all network adapters..." -ForegroundColor Yellow
    Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"} | Disable-NetAdapter -Confirm:$false
}

function Enable-NetworkAdapters {
    Write-Host "Enabling all network adapters..." -ForegroundColor Green
    Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Disabled"} | Enable-NetAdapter -Confirm:$false
}

