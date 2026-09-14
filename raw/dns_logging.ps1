# ============================================
# Windows DNS Client Logging (High Signal)
# ============================================

Write-Host "Enabling DNS client logging..." -ForegroundColor Cyan

# -------------------------------
# 1. Enable DNS Client operational log
# -------------------------------

$dnsLog = "Microsoft-Windows-DNS-Client/Operational"

wevtutil set-log $dnsLog /enabled:true
wevtutil set-log $dnsLog /ms:67108864

Write-Host "DNS Operational log enabled and expanded."

# -------------------------------
# 2. Enable detailed DNS auditing
# -------------------------------

auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable | Out-Null

# -------------------------------
# 3. Enable additional DNS diagnostics (registry)
# -------------------------------

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Force | Out-Null

New-ItemProperty `
    -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" `
    -Name "EnableLogging" `
    -PropertyType DWORD `
    -Value 1 `
    -Force | Out-Null

Write-Host "DNS diagnostic logging enabled."

# -------------------------------
# 4. Quick status output
# -------------------------------

Write-Host ""
Write-Host "=== DNS logging enabled ===" -ForegroundColor Green
Write-Host ""
Write-Host "View in Event Viewer:"
Write-Host "  Applications and Services Logs"
Write-Host "    → Microsoft"
Write-Host "      → Windows"
Write-Host "        → DNS Client"
Write-Host "          → Operational"
Write-Host ""
Write-Host "Key DNS Event IDs:"
Write-Host "  3008 = Query sent"
Write-Host "  3009 = Response received"
Write-Host "  3010 = Query failed"
Write-Host ""
Write-Host "You now have DNS visibility." -ForegroundColor Cyan