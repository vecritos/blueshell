# Blueshellctl network security protocol state machine

$Script:ProtocolStates = @(
    "Uninitialized",
    "Assessing",
    "Enforcing",
    "Protected",
    "Degraded",
    "Lockdown",
    "RecoveryRequired"
)

$Script:ProtocolTransitions = @{
    Uninitialized    = @{ Start = "Assessing" }
    Assessing        = @{ PolicyApplied = "Enforcing"; EmergencyStop = "Lockdown" }
    Enforcing        = @{ VerificationPassed = "Protected"; VerificationFailed = "Degraded"; EmergencyStop = "Lockdown" }
    Protected        = @{ HealthCheckFailed = "Degraded"; EmergencyStop = "Lockdown" }
    Degraded         = @{ RecoveryStarted = "RecoveryRequired"; EmergencyStop = "Lockdown" }
    RecoveryRequired = @{ RecoverySucceeded = "Assessing"; EmergencyStop = "Lockdown" }
    Lockdown         = @{ Reset = "Assessing" }
}

function New-ProtocolState {
    param(
        [string]$State = "Uninitialized",
        [string]$LastEvent = $null,
        [string]$Error = $null
    )

    [pscustomobject]@{
        State = $State
        PreviousState = $null
        LastEvent = $LastEvent
        Error = $Error
        UpdatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
}

function Get-ProtocolState {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return New-ProtocolState
    }

    try {
        $state = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop | ConvertFrom-Json -ErrorAction Stop
        if ($Script:ProtocolStates -notcontains $state.State) {
            throw "Unknown protocol state '$($state.State)'."
        }
        return $state
    } catch {
        throw "Protocol state at '$Path' is invalid: $($_.Exception.Message)"
    }
}

function Set-ProtocolState {
    param(
        [Parameter(Mandatory)][string]$Path,
        [Parameter(Mandatory)][object]$State
    )

    if ($Script:ProtocolStates -notcontains $State.State) {
        throw "Cannot persist unknown protocol state '$($State.State)'."
    }

    $directory = Split-Path -Parent $Path
    if ($directory -and -not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }

    $temporaryPath = "$Path.tmp"
    $State | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $temporaryPath -Encoding UTF8
    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

function Get-ProtocolTransition {
    param(
        [Parameter(Mandatory)][string]$State,
        [Parameter(Mandatory)][string]$Event
    )

    if ($Script:ProtocolStates -notcontains $State) {
        throw "Unknown protocol state '$State'."
    }

    $transition = $Script:ProtocolTransitions[$State][$Event]
    if (-not $transition) {
        throw "Event '$Event' is not valid while protocol is in '$State'."
    }

    return $transition
}

function Invoke-ProtocolTransition {
    param(
        [Parameter(Mandatory)][object]$State,
        [Parameter(Mandatory)][string]$Event
    )

    $nextState = Get-ProtocolTransition -State $State.State -Event $Event
    [pscustomobject]@{
        State = $nextState
        PreviousState = $State.State
        LastEvent = $Event
        Error = $null
        UpdatedAt = (Get-Date).ToUniversalTime().ToString("o")
    }
}