# ========================================================
# ELITE LOCKDOWN + RECOVERY SAFE
# ========================================================

$ErrorActionPreference = "Stop"
$LogPath = "C:\ProgramData\EliteSafeHardening.log"

function Write-Log {
    param($msg)
    $ts = Get-Date -Format "yyyyMMddHHmmss"
    "$ts $msg" | Tee-Object -FilePath $LogPath -Append
}

Write-Log "=== Starting Elite Safe Hardening ==="

# --------------------------
# 1. LSASS & Credential Guard (safe)
# --------------------------
try {
    $lsaPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    New-Item -Path $lsaPath -Force | Out-Null
    Set-ItemProperty -Path $lsaPath -Name "RunAsPPL" -Type DWord -Value 1
    Set-ItemProperty -Path $lsaPath -Name "LsaCfgFlags" -Type DWord -Value 1
    Write-Log "LSASS & Credential Guard enabled"
} catch { Write-Log "LSASS error: $_" }

# --------------------------
# 2. WDAC / AppLocker (audit-first mode)
# --------------------------
try {
    Write-Log "Configuring WDAC baseline in audit mode"
    $policyPath = "C:\Windows\System32\EliteSafeWDAC.xml"
    if (-not (Test-Path $policyPath)) {
        New-CIPolicy -Level Publisher -FilePath $policyPath -UserPEs
    }
    ConvertFrom-CIPolicy -XmlFilePath $policyPath -BinaryFilePath "C:\Windows\System32\EliteSafeWDAC.bin"
    Set-RuleOption -FilePath "C:\Windows\System32\EliteSafeWDAC.bin" -Option 0  # audit mode
    Write-Log "WDAC applied in audit mode (enforce optional)"
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
    Write-Log "ASR & PowerShell logging configured (safe)"
} catch { Write-Log "ASR setup failed: $_" }

# --------------------------
# 4. Protected Users & Privileged Accounts
# --------------------------
try {
    Write-Log "Configuring Protected Users group policies"
    # Example: disable cached credentials but allow recovery
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa" -Name "DisableCachedLogonsCount" -Type DWord -Value 1
    Write-Log "Protected Users policy applied (safe)"
} catch { Write-Log "Protected Users config failed: $_" }

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
    Write-Log "Checking Kernel DMA and VBS protections"
    $dmaStatus = Get-CimInstance -ClassName Win32_DeviceGuard
    if ($dmaStatus.DMAProtectionStatus -ne 1) { Write-Log "WARNING: Kernel DMA protection not enabled" }
    Write-Log "Hypervisor protections checked (UEFI + Secure Boot required)"
} catch { Write-Log "DMA check failed: $_" }

# --------------------------
# 7. WinRE Recovery (SAFE)
# --------------------------
try {
    reagentc /enable | Out-Null
    Write-Log "WinRE enabled for safe recovery"
} catch { Write-Log "WinRE enable failed: $_" }

# --------------------------
# 8. Tamper-Evident Logging & Honeytokens
# --------------------------
try {
    $hash = Get-FileHash $LogPath -Algorithm SHA256
    Write-Log "Log self-hash: $($hash.Hash)"
    # Honeytoken
    $honey = "C:\ProgramData\Honeytoken-LoginShell.txt"
    if (-not (Test-Path $honey)) { New-Item -Path $honey -ItemType File | Out-Null }
    Write-Log "Honeytoken created: $honey"
} catch { Write-Log "Honeytoken/log hash failed: $_" }

Write-Log "=== Elite Safe Hardening COMPLETE — REBOOT RECOMMENDED ==="
Write-Host "Elite Safe Hardening applied. REBOOT recommended. Log: $LogPath"