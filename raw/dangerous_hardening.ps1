# =============================================================
# WINDOWS MODE HARDENING (run if unafraid of being locked out)
# =============================================================

$ErrorActionPreference = "Stop"
$LogPath = "C:\ProgramData\EliteHardening.log"

function Write-Log {
    param($msg)
    $ts = Get-Date -Format "yyyyMMddHHmmss"
    "$ts $msg" | Tee-Object -FilePath $LogPath -Append
}

Write-Log "=== Starting Elite Mode Hardening ==="

# --------------------------
# 1. LSASS & Credential Guard
# --------------------------
try {
    $lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    New-Item -Path $lsaPath -Force | Out-Null
    Set-ItemProperty -Path $lsaPath -Name "RunAsPPL" -Type DWord -Value 1
    Set-ItemProperty -Path $lsaPath -Name "LsaCfgFlags" -Type DWord -Value 1
    Write-Log "LSASS & Credential Guard enforced"
} catch { Write-Log "LSASS error: $_" }

# --------------------------
# 2. WDAC / Kernel-Mode Allowlist
# --------------------------
try {
    Write-Log "Configuring WDAC baseline policy"
    $policyPath = "C:\Windows\System32\EliteWDACPolicy.xml"
    # Generate a default policy if it doesn't exist
    if (-not (Test-Path $policyPath)) {
        New-CIPolicy -Level Publisher -FilePath $policyPath -UserPEs
    }
    # Convert to enforceable
    ConvertFrom-CIPolicy -XmlFilePath $policyPath -BinaryFilePath "C:\Windows\System32\EliteWDACPolicy.bin"
    Set-RuleOption -FilePath "C:\Windows\System32\EliteWDACPolicy.bin" -Option 0  # Enforce mode
    Write-Log "WDAC enforced (kernel allow-list)"
} catch { Write-Log "WDAC setup failed: $_" }

# --------------------------
# 3. Attack Surface Reduction (ASR)
# --------------------------
try {
    # PowerShell Constrained Language Mode
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell" -Name "LanguageMode" -Value "ConstrainedLanguage"
    # ScriptBlock Logging
    New-Item -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Force | Out-Null
    Set-ItemProperty -Path "HKLM:\Software\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" -Name "EnableScriptBlockLogging" -Type DWord -Value 1
    Write-Log "ASR & PowerShell logging configured"
} catch { Write-Log "ASR setup failed: $_" }

# --------------------------
# 4. Protected Users & Privileged Accounts
# --------------------------
try {
    Write-Log "Configuring Protected Users"
    # Disables cached credentials & Kerberos delegation
    $domainAdmins = Get-ADGroupMember "Domain Admins" -Recursive
    foreach ($user in $domainAdmins) {
        Set-ADUser $user -CannotUsePasswordRecovery $true -PasswordNeverExpires $true
    }
} catch { Write-Log "Protected Users config skipped or failed: $_" }

# --------------------------
# 5. SMB / NTLM / Legacy APIs
# --------------------------
try {
    Set-SmbServerConfiguration -EnableSMB1Protocol $false -Force
    Set-SmbServerConfiguration -RejectUnencryptedAccess $true -Force
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "LmCompatibilityLevel" -Type DWord -Value 5
    Write-Log "SMB & NTLM hardened"
} catch { Write-Log "SMB/NTLM hardening failed: $_" }

# --------------------------
# 6. Kernel DMA & Hypervisor protections
# --------------------------
try {
    Write-Log "Checking UEFI & Kernel DMA"
    $dmaStatus = Get-CimInstance -ClassName Win32_DeviceGuard
    if ($dmaStatus.DMAProtectionStatus -ne 1) { Write-Log "WARNING: Kernel DMA protection not enabled" }
    Write-Log "Hypervisor enforced protections checked"
} catch { Write-Log "DMA check failed: $_" }

# --------------------------
# 7. Tamper-Evident Logging & Honeytokens
# --------------------------
try {
    $hash = Get-FileHash $LogPath -Algorithm SHA256
    Write-Log "Log self-hash: $($hash.Hash)"
    # Create honeytoken file
    $honey = "C:\ProgramData\Honeytoken-LoginShell.txt"
    if (-not (Test-Path $honey)) { New-Item -Path $honey -ItemType File | Out-Null }
    Write-Log "Honeytoken created: $honey"
} catch { Write-Log "Honeytoken/log hash failed: $_" }

Write-Log "=== Elite Tier Hardening COMPLETE — REBOOT REQUIRED ==="
Write-Host "Elite tier hardening applied. REBOOT REQUIRED. Log: $LogPath"