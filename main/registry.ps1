# ==========================================
# Blueshellctl Registry & Security Hardening Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
$Script:RegistryStateFile = Join-Path $Script:BlueshellctlRoot "registry.json"

function Initialize-RegistryHardening {
    if (-not (Test-Path $Script:BlueshellctlRoot)) {
        New-Item -ItemType Directory -Path $Script:BlueshellctlRoot -Force | Out-Null
    }
    if (-not (Test-Path $Script:RegistryStateFile)) {
        $state = @{ completed = $false; timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss") }
        $state | ConvertTo-Json | Set-Content -Path $Script:RegistryStateFile -Encoding UTF8
    }
}

function Get-RegistryHardeningState {
    Initialize-RegistryHardening
    Get-Content $Script:RegistryStateFile -Raw | ConvertFrom-Json
}

function Set-RegistryHardeningState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:RegistryStateFile -Encoding UTF8
}

function Invoke-RegistryHardening {
    Write-Host "Applying registry and USB/network hardening..." -ForegroundColor Cyan

    # ------------------------------------------------
    # LSA / Credential Guard
    # ------------------------------------------------
    $lsa = "HKLM:\SYSTEM\CurrentControlSet\Control\Lsa"
    New-Item $lsa -Force | Out-Null
    Set-ItemProperty $lsa RunAsPPL 1 -Type DWord
    Set-ItemProperty $lsa DisableDomainCreds 1 -Type DWord
    Set-ItemProperty $lsa LimitBlankPasswordUse 1 -Type DWord
    Set-ItemProperty $lsa LsaCfgFlags 1 -Type DWord

    # ------------------------------------------------
    # UAC Hardening
    # ------------------------------------------------
    $uac = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
    Set-ItemProperty $uac EnableLUA 1 -Type DWord
    Set-ItemProperty $uac ConsentPromptBehaviorAdmin 2 -Type DWord
    Set-ItemProperty $uac PromptOnSecureDesktop 1 -Type DWord
    Set-ItemProperty $uac EnableInstallerDetection 1 -Type DWord

    # ------------------------------------------------
    # USB Storage Block (AUX unaffected)
    # ------------------------------------------------
    $usbstor = "HKLM:\SYSTEM\CurrentControlSet\Services\USBSTOR"
    New-Item $usbstor -Force | Out-Null
    Set-ItemProperty $usbstor Start 4 -Type DWord

    # ------------------------------------------------
    # Device Installation Restrictions (Default Deny)
    # ------------------------------------------------
    $dev = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeviceInstall\Restrictions"
    New-Item $dev -Force | Out-Null
    Set-ItemProperty $dev DenyUnspecified 1 -Type DWord
    Set-ItemProperty $dev DenyRemovableDevices 1 -Type DWord

    # ------------------------------------------------
    # PowerShell lockdown
    # ------------------------------------------------
    $ps = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell"
    New-Item $ps -Force | Out-Null
    Set-ItemProperty $ps ExecutionPolicy "AllSigned"
    Set-ItemProperty $ps EnableScriptBlockLogging 1 -Type DWord
    Set-ItemProperty $ps EnableTranscripting 1 -Type DWord

    # ------------------------------------------------
    # Disable Windows Script Host
    # ------------------------------------------------
    $wsh = "HKLM:\SOFTWARE\Microsoft\Windows Script Host\Settings"
    New-Item $wsh -Force | Out-Null
    Set-ItemProperty $wsh Enabled 0 -Type DWord

    # ------------------------------------------------
    # SMB Hardening
    # ------------------------------------------------
    $smb = "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters"
    New-Item $smb -Force | Out-Null
    Set-ItemProperty $smb SMB1 0 -Type DWord
    Set-ItemProperty $smb RequireSecuritySignature 1 -Type DWord

    # ------------------------------------------------
    # RDP Disabled
    # ------------------------------------------------
    $rdp = "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server"
    Set-ItemProperty $rdp fDenyTSConnections 1 -Type DWord

    # ------------------------------------------------
    # Disable Autorun / Autoplay
    # ------------------------------------------------
    $explorer = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer"
    New-Item $explorer -Force | Out-Null
    Set-ItemProperty $explorer NoDriveTypeAutoRun 255 -Type DWord
    Set-ItemProperty $explorer NoViewContextMenu 0 -Type DWord

    # ------------------------------------------------
    # Event log hardening
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
    # Disable legacy boot flags
    # ------------------------------------------------
    $boot = "HKLM:\SYSTEM\CurrentControlSet\Control"
    Set-ItemProperty $boot PEFirmwareType 2 -Type DWord  # Expect UEFI

    # Update state
    $state = Get-RegistryHardeningState
    $state.completed = $true
    $state.timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-RegistryHardeningState -State $state

    Write-Host "Registry and USB/network hardening complete." -ForegroundColor Green
    Write-Host "Reboot recommended." -ForegroundColor Yellow
}

