# ==============================
# LEVEL 2 WINDOWS HARDENING
# Paranoid but Gaming-Compatible
# Run as Administrator
# ==============================

Write-Host "Starting Level 2 Hardening..." -ForegroundColor Cyan

# ------------------------------
# 1. Disable SMBv1
# ------------------------------
Write-Host "Disabling SMBv1..."
Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart -ErrorAction SilentlyContinue

# ------------------------------
# 2. Disable NTLMv1
# ------------------------------
Write-Host "Disabling NTLMv1..."
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "LmCompatibilityLevel" -Value 5 -PropertyType DWord -Force

# ------------------------------
# 3. Disable WDigest
# ------------------------------
Write-Host "Disabling WDigest..."
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest" `
    -Name "UseLogonCredential" -Value 0 -PropertyType DWord -Force

# ------------------------------
# 4. Enable LSA Protection
# ------------------------------
Write-Host "Enabling LSA Protection..."
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "RunAsPPL" -Value 1 -PropertyType DWord -Force

# ------------------------------
# 5. Enable Exploit Protection Defaults
# ------------------------------
Write-Host "Enabling system exploit mitigations..."
Set-ProcessMitigation -System -Enable DEP,SEHOP,CFG,ASLR

# ------------------------------
# 6. Disable Remote Registry
# ------------------------------
Write-Host "Disabling Remote Registry..."
Set-Service -Name RemoteRegistry -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name RemoteRegistry -Force -ErrorAction SilentlyContinue

# ------------------------------
# 7. Disable Remote Desktop
# ------------------------------
Write-Host "Disabling Remote Desktop..."
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
    -Name "fDenyTSConnections" -Value 1

Set-Service -Name FDResPub -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name FDResPub -Force -ErrorAction SilentlyContinue

# ------------------------------
# 8. Disable Network Discovery
# ------------------------------
Write-Host "Disabling Network Discovery..."
Set-Service -Name FDResPub -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service -Name FDResPub -Force -ErrorAction SilentlyContinue

# ------------------------------
# 9. Block PowerShell Outbound (Optional but recommended)
# ------------------------------
Write-Host "Blocking outbound PowerShell..."
New-NetFirewallRule -DisplayName "Block PowerShell Outbound" `
    -Direction Outbound `
    -Program "%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" `
    -Action Block -Profile Any -ErrorAction SilentlyContinue

# -------------------------------------------------
# 99. Enable Memory Integrity (HVCI)
# -------------------------------------------------
Write-Host "Enabling Memory Integrity (requires reboot)..."

New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Force | Out-Null
New-Item -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" -Force | Out-Null

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" `
    -Name "EnableVirtualizationBasedSecurity" -Value 1 -PropertyType DWord -Force

New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard\Scenarios\HypervisorEnforcedCodeIntegrity" `
    -Name "Enabled" -Value 1 -PropertyType DWord -Force


# ------------------------------
# 10. Disable SMB Anonymous Enumeration
# ------------------------------
Write-Host "Disabling anonymous enumeration..."
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" `
    -Name "RestrictAnonymous" -Value 1 -PropertyType DWord -Force

# ------------------------------
# 11. Ensure Firewall is Enabled
# ------------------------------
Write-Host "Ensuring Windows Firewall is enabled..."
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# ------------------------------
# 12. UAC to Maximum
# ------------------------------
Write-Host "Setting UAC to maximum..."
New-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" `
    -Name "ConsentPromptBehaviorAdmin" -Value 2 -PropertyType DWord -Force

# -------------------------------------------------
# 13. Enable Defender Attack Surface Reduction Rules
# -------------------------------------------------
Write-Host "Enabling Defender ASR Rules..."

$ASRRules = @{
    # Block credential stealing from LSASS
    "9e6c4e1f-7a1a-4e16-8f64-ff5c7a8e36c3" = "Enabled"
    # Block Office child processes
    "d4f940ab-401b-4efc-aadc-ad5f3c50688a" = "Enabled"
    # Block executable content from email/webmail
    "be9ba2d9-53ea-4cdc-84e5-9b1eeee46550" = "Enabled"
    # Block Win32 API calls from Office
    "92e97fa1-2edf-4476-bdd6-9dd0b4dddc7b" = "Enabled"
    # Block persistence via WMI
    "e6db77e5-3df2-4cf1-b95a-636979351e5b" = "Enabled"
}

foreach ($rule in $ASRRules.Keys) {
    Add-MpPreference -AttackSurfaceReductionRules_Ids $rule `
                     -AttackSurfaceReductionRules_Actions Enabled `
                     -ErrorAction SilentlyContinue
}

# -------------------------------------------------
# 14. Enforce BitLocker (C: Drive)
# -------------------------------------------------
Write-Host "Checking BitLocker status..."

$BLV = Get-BitLockerVolume -MountPoint "C:"

if ($BLV.VolumeStatus -ne "FullyEncrypted") {
    Write-Host "Enabling BitLocker on C: ..."
    Enable-BitLocker -MountPoint "C:" `
        -EncryptionMethod XtsAes256 `
        -UsedSpaceOnly `
        -TpmProtector
} else {
    Write-Host "BitLocker already enabled."
}

Write-Host "Hardening complete. Reboot required." -ForegroundColor Green

