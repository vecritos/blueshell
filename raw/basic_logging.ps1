# ============================================
# Windows Network & Firewall Logging Baseline
# ============================================

Write-Host "Configuring enhanced logging..." -ForegroundColor Cyan

# -------------------------------
# 1. Windows Firewall logging
# -------------------------------

$fwLog = "$env:SystemRoot\System32\LogFiles\Firewall\pfirewall.log"

Set-NetFirewallProfile -Profile Domain,Public,Private `
    -LogAllowed True `
    -LogBlocked True `
    -LogFileName $fwLog `
    -LogMaxSizeKilobytes 65536

Write-Host "Firewall logging enabled."

# -------------------------------
# 2. Expand key event log sizes
# -------------------------------

wevtutil sl Security /ms:134217728
wevtutil sl System /ms:67108864
wevtutil sl Microsoft-Windows-Windows Firewall With Advanced Security/Firewall /ms:67108864

Write-Host "Event log sizes increased."

# -------------------------------
# 3. Enable Filtering Platform events
# (THIS IS THE GOOD STUFF)
# -------------------------------

auditpol /set /subcategory:"Filtering Platform Connection" /success:enable /failure:enable | Out-Null
auditpol /set /subcategory:"Filtering Platform Packet Drop" /success:enable /failure:enable | Out-Null

Write-Host "Filtering Platform auditing enabled."

# -------------------------------
# 4. Enable process creation logging (helps correlate)
# -------------------------------

auditpol /set /subcategory:"Process Creation" /success:enable | Out-Null

# Optional but VERY useful: include command line
New-ItemProperty `
  -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System\Audit" `
  -Name "ProcessCreationIncludeCmdLine_Enabled" `
  -Value 1 `
  -PropertyType DWORD `
  -Force | Out-Null

Write-Host "Process creation auditing enabled."

# -------------------------------
# 5. Quick status output
# -------------------------------

Write-Host ""
Write-Host "=== Logging baseline complete ===" -ForegroundColor Green
Write-Host "Firewall log: $fwLog"
Write-Host ""
Write-Host "Key Event Viewer locations:"
Write-Host "  Security log → Filtering Platform (5152, 5157)"
Write-Host "  Security log → Process Creation (4688)"
Write-Host ""
Write-Host "You now have real visibility." -ForegroundColor Cyan