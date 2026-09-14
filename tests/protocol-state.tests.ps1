$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "..\main\protocol-state.ps1")

function Assert-Equal {
    param([object]$Actual, [object]$Expected, [string]$Message)
    if ($Actual -ne $Expected) {
        throw "$Message. Expected '$Expected', got '$Actual'."
    }
}

$statePath = Join-Path ([System.IO.Path]::GetTempPath()) "blueshellctl-protocol-$([guid]::NewGuid()).json"
try {
    $state = Get-ProtocolState -Path $statePath
    Assert-Equal $state.State "Uninitialized" "A missing state file should start uninitialized"

    $state = Invoke-ProtocolTransition -State $state -Event "Start"
    Assert-Equal $state.State "Assessing" "Start should enter assessment"

    $state = Invoke-ProtocolTransition -State $state -Event "PolicyApplied"
    Assert-Equal $state.State "Enforcing" "PolicyApplied should enter enforcement"

    $state = Invoke-ProtocolTransition -State $state -Event "VerificationPassed"
    Assert-Equal $state.State "Protected" "Successful verification should protect the system"

    $failed = $false
    try {
        Invoke-ProtocolTransition -State $state -Event "PolicyApplied"
    } catch {
        $failed = $true
    }
    Assert-Equal $failed $true "Invalid transitions must fail closed"

    Set-ProtocolState -Path $statePath -State $state
    $loaded = Get-ProtocolState -Path $statePath
    Assert-Equal $loaded.State "Protected" "Persisted state should round-trip"

    Write-Output "protocol-state smoke test passed"
} finally {
    Remove-Item -LiteralPath $statePath -Force -ErrorAction SilentlyContinue
}