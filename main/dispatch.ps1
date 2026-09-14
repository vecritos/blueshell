# ==========================================
# Blueshellctl CLI Dispatch Module
# ==========================================

param(
    [Parameter(Position=0)]
    [string]$Verb = "help",
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$CommandArgs
)

$Script:IsReadOnlyRequest = @("help", "examples") -contains $Verb.ToLower()

if (-not $Script:IsReadOnlyRequest) {
# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

# Module Root
$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
if (-not (Test-Path $Script:BlueshellctlRoot)) {
    New-Item -ItemType Directory -Path $Script:BlueshellctlRoot -Force | Out-Null
}

$Script:BlueshellctlModuleRoot = $PSScriptRoot

# Import submodules
$Modules = @("wsl.ps1","network.ps1","logging.ps1")
foreach ($mod in $Modules) {
    $path = Join-Path $Script:BlueshellctlModuleRoot $mod
    if (Test-Path $path) {
        . $path
    } else {
        Write-Warning "Module $mod not found at $path"
    }
}
}

function Show-Help {
    Write-Host "Blueshellctl - Windows network security controls" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Run the smoke test first:"
    Write-Host "  powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\protocol-state.tests.ps1"
    Write-Host ""
    Write-Host "Safe status commands:"
    Write-Host "  .\main\blueshellctl.ps1 help"
    Write-Host "  .\main\blueshellctl.ps1 examples"
    Write-Host "  .\main\blueshellctl.ps1 protocol-status"
    Write-Host ""
    Write-Host "Protocol flow:"
    Write-Host "  Uninitialized -> Assessing -> Enforcing -> Protected"
    Write-Host "  Failures go to Degraded or RecoveryRequired. EmergencyStop goes to Lockdown."
    Write-Host ""
    Write-Host "Commands and arguments:"
    Write-Host "  protocol-status"
    Write-Host "  protocol-transition <event>"
    Write-Host "    Events: Start, PolicyApplied, VerificationPassed, VerificationFailed,"
    Write-Host "    HealthCheckFailed, RecoveryStarted, RecoverySucceeded, EmergencyStop, Reset"
    Write-Host "  bootstrap system | bootstrap-status | bootstrap-reset"
    Write-Host "    system is currently the only supported bootstrap object."
    Write-Host "  network-harden | network-disable | network-enable"
    Write-Host "  logs-open [log-name]"
    Write-Host "    Default log: blueshellctl.log"
    Write-Host "  logs-inspect [log-name] [--shred <max|quick>]"
    Write-Host "    Default log: blueshellctl.log; default mode: max"
    Write-Host "    Examples: logs-inspect; logs-inspect session.log --shred quick"
    Write-Host "              logs-inspect --shred max"
    Write-Host "  wsl-setup | registry-harden"
    Write-Host "    These commands take no arguments."
    Write-Host ""
    Write-Host "Operational commands require an elevated PowerShell window and can"
    Write-Host "change firewall, adapters, registry, WSL, users, or log files."
}

function Show-Examples {
    Write-Host "Blueshellctl walkthrough" -ForegroundColor Cyan
    Write-Host "These commands are printed for review; they are not executed."
    Write-Host ""
    Write-Host "1. Safe smoke test:"
    Write-Host "   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\protocol-state.tests.ps1"
    Write-Host "   This checks state creation, transitions, rejection, and persistence."
    Write-Host "2. Read-only orientation:"
    Write-Host "   .\main\blueshellctl.ps1 help"
    Write-Host "   .\main\blueshellctl.ps1 protocol-status"
    Write-Host "   These commands only explain the tool or read saved state."
    Write-Host "3. From an elevated PowerShell window, walk the protocol:"
    Write-Host "   .\main\blueshellctl.ps1 protocol-transition Start"
    Write-Host "   .\main\blueshellctl.ps1 protocol-transition PolicyApplied"
    Write-Host "   .\main\blueshellctl.ps1 protocol-transition VerificationPassed"
    Write-Host "   This records the protocol state; it does not yet enforce network policy automatically."
    Write-Host "4. Finite state machine:"
    Write-Host "   Uninitialized --Start--> Assessing --PolicyApplied--> Enforcing"
    Write-Host "                                      |                         |"
    Write-Host "                              EmergencyStop             VerificationPassed"
    Write-Host "                                      v                         v"
    Write-Host "                                  Lockdown                 Protected"
    Write-Host "                                      ^                         |"
    Write-Host "                                      +--EmergencyStop----------+"
    Write-Host "   Enforcing --VerificationFailed--> Degraded"
    Write-Host "   Protected --HealthCheckFailed--> Degraded"
    Write-Host "   Degraded --RecoveryStarted--> RecoveryRequired"
    Write-Host "   RecoveryRequired --RecoverySucceeded--> Assessing"
    Write-Host "   Lockdown --Reset--> Assessing"
    Write-Host "   Only events valid for the current state are accepted."
    Write-Host "5. Bootstrap and platform commands:"
    Write-Host "   .\main\blueshellctl.ps1 bootstrap-status"
    Write-Host "   .\main\blueshellctl.ps1 bootstrap system"
    Write-Host "   .\main\blueshellctl.ps1 network-harden"
    Write-Host "   .\main\blueshellctl.ps1 registry-harden"
    Write-Host "   .\main\blueshellctl.ps1 wsl-setup"
    Write-Host "   Review status first; these commands can change system configuration."
    Write-Host "6. Logging commands:"
    Write-Host "   .\main\blueshellctl.ps1 logs-open"
    Write-Host "   .\main\blueshellctl.ps1 logs-open session.log"
    Write-Host "   .\main\blueshellctl.ps1 logs-inspect session.log --shred quick"
    Write-Host "   Shred modes are max or quick; inspection can alter logs and adapters."
    Write-Host "   logs-open captures recent Windows System/Application events. logs-inspect modifies log contents."
    Write-Host ""
    Write-Host "Read README.md and the matching main\ script before executing privileged commands."
}

function Invoke-Blueshellctl {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Verb,
        [Parameter(Position=1)]
        [string[]]$Args
    )

    switch ($Verb.ToLower()) {
        "help" { Show-Help }
        "examples" { Show-Examples }

        # WSL
        "wsl-setup" { Invoke-WSLSetup @Args }

        # Network
        "network-harden" { Invoke-NetworkHarden }
        "network-disable" { Disable-NetworkAdapters }
        "network-enable" { Enable-NetworkAdapters }

        # Logs
        "logs-open" {
            $logName = if ($Args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace($Args[0])) {
                $Args[0]
            } else {
                "blueshellctl.log"
            }
            Open-Logs -LogName $logName
        }
        "logs-inspect" {
            $logName = if ($Args.Count -gt 0) { $Args[0] } else { "blueshellctl.log" }
            $shredMode = "max"
            if ($Args.Count -eq 2 -and $Args[0] -eq "--shred") {
                $logName = "blueshellctl.log"
                $shredMode = $Args[1]
            } elseif ($Args.Count -eq 2) {
                $shredMode = $Args[1]
            } elseif ($Args.Count -eq 3 -and $Args[1] -eq "--shred") {
                $shredMode = $Args[2]
            }
            Inspect-Logs -LogName $logName -ShredMode $shredMode
        }

        # Bootstrap
        "bootstrap-status" {
            $bs = Get-Content (Join-Path $Script:BlueshellctlRoot "bootstrap.json") -Raw | ConvertFrom-Json
            Write-Host "Bootstrap status:"
            $bs | Format-List
        }
        "bootstrap-reset" {
            Write-Host "Resetting bootstrap..."
            # Re-fetch files from repo (placeholder)
            Write-Host "Pulling latest blueshellctl files from repository..."
            # Re-enable network if needed
            Enable-NetworkAdapters
            # Call bootstrapping
            . (Join-Path $Script:BlueshellctlRoot "bootstrap.ps1")
            Disable-NetworkAdapters
            Write-Host "Bootstrap reset complete."
        }

        Default { Write-Warning "Unknown verb '$Verb'. Run 'blueshellctl help' for usage." }
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-Blueshellctl -Verb $Verb -Args $CommandArgs
}

