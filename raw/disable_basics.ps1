# ============================================
# Disable Unused Default Windows Firewall Rules
# Safe Hardening Baseline
# ============================================

Write-Host "Disabling non-essential default firewall rule groups..." -ForegroundColor Cyan

$groups = @(
    "Cast to Device functionality",
    "Network Discovery",
    "File and Printer Sharing",
    "Remote Assistance",
    "Remote Desktop",
    "Windows Media Player Network Sharing Service",
    "Delivery Optimization",
    "BranchCache",
    "Xbox Live Networking Service",
    "Connected Devices Platform",
    "Function Discovery Provider Host",
    "Function Discovery Resource Publication"
)

foreach ($group in $groups) {
    $rules = Get-NetFirewallRule -DisplayGroup $group -ErrorAction SilentlyContinue
    if ($rules) {
        $rules | Set-NetFirewallRule -Enabled False
        Write-Host "Disabled: $group" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Consumer-facing firewall rules disabled." -ForegroundColor Green
Write-Host "Core networking remains intact."