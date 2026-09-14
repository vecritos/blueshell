# ==========================================
# REGISTRY HARDENING — MALICIOUS MAID AWARE
# ==========================================

if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

Write-Host "Applying registry hardening..." -ForegroundColor Cyan

# ------------------------------------------------
# LSA / CREDENTIAL THEFT HARDENING
# ------------------------------------------------
$lsa = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
New-Item $lsa -Force | Out-Null
Set-ItemProperty $lsa RunAsPPL 1 -Type DWord
Set-ItemProperty $lsa DisableDomainCreds 1 -Type DWord
Set-ItemProperty $lsa LimitBlankPasswordUse 1 -Type DWord
Set-ItemProperty $lsa LsaCfgFlags 1 -Type DWord   # Credential Guard

# ------------------------------------------------
# UAC HARDENING
# ------------------------------------------------
$uac = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
Set-ItemProperty $uac EnableLUA 1 -Type DWord
Set-ItemProperty $uac ConsentPromptBehaviorAdmin 2 -Type DWord
Set-ItemProperty $uac PromptOnSecureDesktop 1 -Type DWord
Set-ItemProperty $uac EnableInstallerDetection 1 -Type DWord

# ------------------------------------------------
# DISABLE USB STORAGE (AUX AUDIO UNAFFECTED)
# ------------------------------------------------
$usbstor = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
New-Item $usbstor -Force | Out-Null
Set-ItemProperty $usbstor Start 4 -Type DWord

# ------------------------------------------------
# DEVICE INSTALL RESTRICTIONS (DEFAULT DENY)
# ------------------------------------------------
$dev = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
New-Item $dev -Force | Out-Null
Set-ItemProperty $dev DenyUnspecified 1 -Type DWord
Set-ItemProperty $dev DenyRemovableDevices 1 -Type DWord

# ------------------------------------------------
# POWERSHELL LOCKDOWN
# ------------------------------------------------
$ps = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
New-Item $ps -Force | Out-Null
Set-ItemProperty $ps ExecutionPolicy "AllSigned"
Set-ItemProperty $ps EnableScriptBlockLogging 1 -Type DWord
Set-ItemProperty $ps EnableTranscripting 1 -Type DWord

# ------------------------------------------------
# DISABLE WINDOWS SCRIPT HOST (VBS / JS)
# ------------------------------------------------
$wsh = "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"
New-Item $wsh -Force | Out-Null
Set-ItemProperty $wsh Enabled 0 -Type DWord

# ------------------------------------------------
# SMB HARDENING (KILL LEGACY)
# ------------------------------------------------
$smb = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
New-Item $smb -Force | Out-Null
Set-ItemProperty $smb SMB1 0 -Type DWord
Set-ItemProperty $smb RequireSecuritySignature 1 -Type DWord

# ------------------------------------------------
# RDP DISABLED
# ------------------------------------------------
$rdp = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
Set-ItemProperty $rdp fDenyTSConnections 1 -Type DWord

# ------------------------------------------------
# DISABLE AUTORUN / AUTOPLAY
# ------------------------------------------------
$explorer = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
New-Item $explorer -Force | Out-Null
Set-ItemProperty $explorer NoDriveTypeAutoRun 255 -Type DWord
Set-ItemProperty $explorer NoViewContextMenu 0 -Type DWord

# ------------------------------------------------
# EVENT LOG HARDENING (ANTI-TAMPER SIGNAL)
# ------------------------------------------------
$log = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\EventLog"
New-Item $log -Force | Out-Null

foreach ($channel in @("Application","Security","System")) {
    $p = "$log\$channel"
    New-Item $p -Force | Out-Null
    Set-ItemProperty $p MaxSize 134217728 -Type DWord  # 128MB
    Set-ItemProperty $p Retention 0 -Type DWord
}

# ------------------------------------------------
# DISABLE LEGACY BOOT BEHAVIOR FLAGS
# ------------------------------------------------
$boot = "HKLM:\SYSTEM\CurrentControlSet\Control"
Set-ItemProperty $boot PEFirmwareType 2 -Type DWord  # UEFI expected

Write-Host "Registry hardening complete." -ForegroundColor Green
Write-Host "Reboot REQUIRED." -ForegroundColor Yellow
