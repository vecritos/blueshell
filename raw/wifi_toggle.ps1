# ============================================
# Wi-Fi Toggle Script
# ============================================

$wifi = Get-NetAdapter | Where-Object {$_.InterfaceDescription -match "Wireless|Wi-Fi|802.11"}

if (-not $wifi) {
    Write-Host "No Wi-Fi adapter found." -ForegroundColor Red
    exit
}

Write-Host "Detected adapter: $($wifi.Name)"
Write-Host ""

Write-Host "Choose action:"
Write-Host "1 = Turn Wi-Fi OFF"
Write-Host "2 = Turn Wi-Fi ON"
$choice = Read-Host "Enter 1 or 2"

switch ($choice) {
    "1" {
        Disable-NetAdapter -Name $wifi.Name -Confirm:$false
        Write-Host "Wi-Fi disabled." -ForegroundColor Yellow
    }
    "2" {
        Enable-NetAdapter -Name $wifi.Name -Confirm:$false
        Write-Host "Wi-Fi enabled." -ForegroundColor Green
    }
    default {
        Write-Host "Invalid choice."
    }
}