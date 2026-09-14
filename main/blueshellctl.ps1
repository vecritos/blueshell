# ==========================================
# Blueshellctl Main CLI / State Machine Module
# ==========================================

param(
    [Parameter(Position=0)]
    [string]$Verb = "help",
    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$CommandArgs
)

$Script:IsReadOnlyRequest = @("help", "examples") -contains $Verb.ToLower()

if (-not $Script:IsReadOnlyRequest) {
# Ensure Administrator
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
if (-not (Test-Path $Script:BlueshellctlRoot)) {
    New-Item -ItemType Directory -Path $Script:BlueshellctlRoot -Force | Out-Null
}

$Script:BlueshellctlModuleRoot = $PSScriptRoot
$Script:ProtocolStateFile = Join-Path $Script:BlueshellctlRoot "protocol-state.json"
. (Join-Path $Script:BlueshellctlModuleRoot "protocol-state.ps1")

# ------------------------------------------------
# Import submodules
# ------------------------------------------------
$Modules = @(
    "bootstrap.ps1",
    "logging.ps1",
    "network.ps1",
    "registry.ps1",
    "wsl.ps1"
)
foreach ($mod in $Modules) {
    $path = Join-Path $Script:BlueshellctlModuleRoot $mod
    if (Test-Path $path) {
        . $path
    } else {
        Write-Warning "Module $mod not found at $path"
    }
}
}

# ------------------------------------------------
# CLI Dispatch
# ------------------------------------------------
function Show-Help {
    Write-Host "Blueshellctl - Windows network security controls" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "What this does:"
    Write-Host "  Blueshellctl applies network, registry, WSL, and logging operations"
    Write-Host "  through an explicit security protocol state machine."
    Write-Host ""
    Write-Host "First steps:"
    Write-Host "  1. Run the smoke test from the repository root:"
    Write-Host "     powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\protocol-state.tests.ps1"
    Write-Host "  2. Open PowerShell as Administrator for the following system commands."
    Write-Host "  3. Read the current protocol state:"
    Write-Host "     .\main\blueshellctl.ps1 protocol-status"
    Write-Host "  4. Start a protocol run only when you understand the requested change:"
    Write-Host "     .\main\blueshellctl.ps1 protocol-transition Start"
    Write-Host ""
    Write-Host "Protocol lifecycle:"
    Write-Host "  Uninitialized -> Assessing -> Enforcing -> Protected"
    Write-Host "  Failures go to Degraded or RecoveryRequired. EmergencyStop goes to Lockdown."
    Write-Host "  Invalid transitions are rejected."
    Write-Host ""
    Write-Host "Available commands:"
    Write-Host "  help"
    Write-Host "      Show this guide. Takes no arguments."
    Write-Host "  examples"
    Write-Host "      Print a safe, command-by-command walkthrough. Takes no arguments."
    Write-Host "  protocol-status"
    Write-Host "      Show the saved protocol state. Takes no arguments."
    Write-Host "  protocol-transition <event>"
    Write-Host "      Apply one valid event for the current state. Events:"
    Write-Host "      Start, PolicyApplied, VerificationPassed, VerificationFailed,"
    Write-Host "      HealthCheckFailed, RecoveryStarted, RecoverySucceeded,"
    Write-Host "      EmergencyStop, Reset. Invalid state/event pairs are rejected."
    Write-Host "  bootstrap system"
    Write-Host "      Run the interactive system bootstrap workflow."
    Write-Host "      'system' is currently the only supported bootstrap object."
    Write-Host "      Use network-harden, registry-harden, wsl-setup, or log commands"
    Write-Host "      separately for those areas."
    Write-Host "  bootstrap-status"
    Write-Host "      Show bootstrap progress. Takes no arguments."
    Write-Host "  bootstrap-reset"
    Write-Host "      Re-run bootstrap after reconnecting the network. Takes no arguments."
    Write-Host "  network-harden"
    Write-Host "      Apply firewall and DNS hardening. Takes no arguments."
    Write-Host "  network-disable"
    Write-Host "      Disable physical network adapters. Takes no arguments."
    Write-Host "  network-enable"
    Write-Host "      Enable disabled physical network adapters. Takes no arguments."
    Write-Host "  logs-open [log-name]"
    Write-Host "      Create or append to a log. Default: blueshellctl.log."
    Write-Host "      Example: logs-open session.log"
    Write-Host "  logs-inspect [log-name] [--shred <mode>]"
    Write-Host "      Inspect and modify a log. Default name: blueshellctl.log."
    Write-Host "      Modes: max (random overwrite) or quick (clear contents)."
    Write-Host "      Examples: logs-inspect; logs-inspect session.log --shred quick"
    Write-Host "                logs-inspect --shred max"
    Write-Host "  wsl-setup"
    Write-Host "      Install and configure WSL. Takes no arguments."
    Write-Host "  registry-harden"
    Write-Host "      Apply Windows registry hardening. Takes no arguments."
    Write-Host ""
    Write-Host "Examples:"
    Write-Host "  .\main\blueshellctl.ps1 protocol-status"
    Write-Host "  .\main\blueshellctl.ps1 logs-open session.log"
    Write-Host "  .\main\blueshellctl.ps1 logs-inspect session.log --shred quick"
    Write-Host ""
    Write-Host "Important:"
    Write-Host "  Run operational commands from an elevated PowerShell window."
    Write-Host "  Network, registry, WSL, bootstrap, and log commands can change the host."
    Write-Host "  Review the command and back up important data before continuing."
    Write-Host "  Runtime state is stored under C:\Program Files\Blueshellctl."
}

function Show-Examples {
    Write-Host "Blueshellctl walkthrough" -ForegroundColor Cyan
    Write-Host "These commands are printed for review; they are not executed."
    Write-Host ""
    Write-Host "1. Safe smoke test:"
    Write-Host "   powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\protocol-state.tests.ps1"
    Write-Host "   Expected output: protocol-state smoke test passed"
    Write-Host "   This checks state creation, valid transitions, invalid-transition rejection, and persistence."
    Write-Host ""
    Write-Host "2. Read-only orientation:"
    Write-Host "   .\main\blueshellctl.ps1 help"
    Write-Host "   .\main\blueshellctl.ps1 examples"
    Write-Host "   .\main\blueshellctl.ps1 protocol-status"
    Write-Host "   These commands explain the tool and read saved state; they do not change adapters or firewall rules."
    Write-Host ""
    Write-Host "3. Open PowerShell as Administrator before continuing."
    Write-Host "   The remaining commands can change the computer."
    Write-Host "   The state file is stored at C:\Program Files\Blueshellctl\protocol-state.json."
    Write-Host ""
    Write-Host "4. Finite state machine:"
    Write-Host ""
    Write-Host "   +----------------+  Start  +-----------+  PolicyApplied  +-----------+"
    Write-Host "   | Uninitialized  | ------> | Assessing | --------------> | Enforcing  |"
    Write-Host "   +----------------+         +-----------+                 +-----------+"
    Write-Host "          ^                         |                              |"
    Write-Host "          | RecoverySucceeded       | EmergencyStop                | VerificationPassed"
    Write-Host "          |                         v                              v"
    Write-Host "   +--------------------+    +----------+                 +-----------+"
    Write-Host "   | RecoveryRequired   |    | Lockdown |                 | Protected |"
    Write-Host "   +--------------------+    +----------+                 +-----------+"
    Write-Host "          ^                         ^                         |       |"
    Write-Host "          | RecoveryStarted         | EmergencyStop           |       | EmergencyStop"
    Write-Host "          |                         |                         |       v"
    Write-Host "   +----------+  HealthCheckFailed  +-------------------------+     +----------+"
    Write-Host "   | Degraded | <---------------- Protected                         | Lockdown |"
    Write-Host "   +----------+                                                     +----------+"
    Write-Host "          |"
    Write-Host "          +-- EmergencyStop -> Lockdown"
    Write-Host "   VerificationFailed: Enforcing -> Degraded"
    Write-Host "   Reset: Lockdown -> Assessing"
    Write-Host ""
    Write-Host "   Only events valid for the current state are accepted."
    Write-Host ""
    Write-Host "5. Walk through the normal protocol path:"
    Write-Host "   .\main\blueshellctl.ps1 protocol-transition Start"
    Write-Host "   .\main\blueshellctl.ps1 protocol-transition PolicyApplied"
    Write-Host "   .\main\blueshellctl.ps1 protocol-transition VerificationPassed"
    Write-Host "   .\main\blueshellctl.ps1 protocol-status"
    Write-Host "   Expected states: Assessing, Enforcing, then Protected"
    Write-Host "   Each event is accepted only when it is valid for the current state."
    Write-Host "   These commands currently record protocol state; they do not apply network policy automatically."
    Write-Host ""
    Write-Host "6. Recovery event overview (review before using):"
    Write-Host "   VerificationFailed -> Degraded"
    Write-Host "   HealthCheckFailed -> Degraded"
    Write-Host "   RecoveryStarted -> RecoveryRequired"
    Write-Host "   RecoverySucceeded -> Assessing"
    Write-Host "   EmergencyStop -> Lockdown"
    Write-Host "   Reset -> Assessing (only from Lockdown)"
    Write-Host "   Use HealthCheckFailed before RecoveryStarted when recovering from Protected."
    Write-Host "   Use EmergencyStop when the safest action is to enter Lockdown immediately."
    Write-Host ""
    Write-Host "7. Bootstrap workflow:"
    Write-Host "   .\main\blueshellctl.ps1 bootstrap-status"
    Write-Host "   .\main\blueshellctl.ps1 bootstrap system"
    Write-Host "   Bootstrap is interactive and can create a local administrator."
    Write-Host "   Check bootstrap-status first so you know whether bootstrap has already run."
    Write-Host ""
    Write-Host "8. Network and platform workflows:"
    Write-Host "   .\main\blueshellctl.ps1 network-harden"
    Write-Host "   .\main\blueshellctl.ps1 network-disable"
    Write-Host "   .\main\blueshellctl.ps1 network-enable"
    Write-Host "   .\main\blueshellctl.ps1 registry-harden"
    Write-Host "   .\main\blueshellctl.ps1 wsl-setup"
    Write-Host "   These can change firewall, DNS, adapters, registry, or WSL."
    Write-Host "   Run one operation at a time and verify the result before continuing."
    Write-Host ""
    Write-Host "9. Logging workflows:"
    Write-Host "   .\main\blueshellctl.ps1 logs-open"
    Write-Host "   .\main\blueshellctl.ps1 logs-open session.log"
    Write-Host "   .\main\blueshellctl.ps1 logs-inspect session.log --shred quick"
    Write-Host "   Valid shred modes: max or quick. Inspection can alter logs and adapters."
    Write-Host "   logs-open captures host metadata and recent Windows System/Application events."
    Write-Host "   logs-inspect is destructive: quick clears contents and max overwrites them."
    Write-Host ""
    Write-Host "Read README.md and the matching script in main\ before running privileged commands."
}

function Invoke-Blueshellctl {
    param(
        [Parameter(Mandatory=$true,Position=0)]
        [string]$Verb,
        [Parameter(Position=1)]
        [string[]]$Args
    )

    switch ($Verb.ToLower()) {

        # -------------------------------
        # Bootstrap
        # -------------------------------
        "bootstrap" {
            if (-not $Args -or $Args.Count -ne 1 -or $Args[0].ToLower() -ne "system") {
                Write-Warning "Specify the supported bootstrap object: system"
                return
            }
            Write-Host "Bootstrapping system..." -ForegroundColor Cyan
            Invoke-Bootstrap
        }
        "bootstrap-status" { 
            $bs = Get-BootstrapState
            Write-Host "Bootstrap status:"; $bs | Format-List
        }
        "bootstrap-reset" {
            Write-Host "Resetting bootstrap..."
            Enable-NetworkAdapters
            Invoke-Bootstrap
            Disable-NetworkAdapters
            Write-Host "Bootstrap reset complete."
        }

        # -------------------------------
        # Network
        # -------------------------------
        "network-harden" { Invoke-NetworkHarden }
        "network-disable" { Disable-NetworkAdapters }
        "network-enable" { Enable-NetworkAdapters }

        # -------------------------------
        # Logs
        # -------------------------------
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

        # -------------------------------
        # WSL
        # -------------------------------
        "wsl-setup" { Invoke-WSLSetup @Args }

        # -------------------------------
        # Registry
        # -------------------------------
        "registry-harden" { Invoke-RegistryHardening }

        # -------------------------------
        # Protocol state machine
        # -------------------------------
        "protocol-status" {
            Get-ProtocolState -Path $Script:ProtocolStateFile | Format-List
        }
        "protocol-transition" {
            if (-not $Args -or $Args.Count -ne 1) {
                Write-Warning "Specify exactly one protocol event"
                return
            }

            $currentState = Get-ProtocolState -Path $Script:ProtocolStateFile
            $nextState = Invoke-ProtocolTransition -State $currentState -Event $Args[0]
            Set-ProtocolState -Path $Script:ProtocolStateFile -State $nextState
            $nextState | Format-List
        }

        # -------------------------------
        # Help
        # -------------------------------
        "help" { Show-Help }
        "examples" { Show-Examples }

        Default { Write-Warning "Unknown verb '$Verb'. Run 'blueshellctl help' for usage." }
    }
}

if ($MyInvocation.InvocationName -ne ".") {
    Invoke-Blueshellctl -Verb $Verb -Args $CommandArgs
}

