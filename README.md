# blueshell

Blueshell is a Windows PowerShell project for network hardening, isolation, and
security monitoring. It is being developed as a fail-closed protocol: actions
are allowed by an explicit state machine, and system-changing modules execute
only as part of a controlled transition.

## Examples

Running examples command gives an overview of system processing `.\main\blueshellctl.ps1 examples`

## Download And Verify

Requirements: Windows PowerShell 5.1 or PowerShell 7+. The smoke test is
designed to run without administrator privileges and does not change networking,
the registry, WSL, or any persistent Blueshellctl state.

```powershell
git clone <repository-url> blueshell
Set-Location .\blueshell
pwsh -NoProfile -File .\tests\protocol-state.tests.ps1
```

On Windows PowerShell 5.1, use this equivalent command:

```powershell
powershell.exe -NoProfile -ExecutionPolicy Bypass -File .\tests\protocol-state.tests.ps1
```

Expected output:

```text
protocol-state smoke test passed
```

The test creates a temporary JSON state file, exercises the normal startup
path, rejects an invalid transition, verifies persistence, and removes the
temporary file when it finishes. A non-zero exit code or an exception means
the checkout should not be pushed as a verified change.

## How It Works

The protocol persists its current state in:

`C:\Program Files\Blueshellctl\protocol-state.json`

The initial lifecycle is:

```text
Uninitialized -> Assessing -> Enforcing -> Protected
						 |
						 +-> Lockdown
```

Failure paths are explicit:

- `VerificationFailed` moves `Enforcing` to `Degraded`.
- `HealthCheckFailed` moves `Protected` to `Degraded`.
- `RecoveryStarted` moves `Degraded` to `RecoveryRequired`.
- `EmergencyStop` moves any operating state to `Lockdown`.
- `Reset` is the only event that leaves `Lockdown`.

Invalid events are rejected and are never persisted. State writes go through a
temporary file before replacement so an interrupted write does not silently
replace the protocol state with partial JSON.

In operation, `main/blueshellctl.ps1` receives a command, the protocol module
checks whether the requested event is legal for the current state, and only
then does the relevant system module perform its side effect. A successful
operation records the next state; a failed verification records a degraded or
recovery state instead of claiming that the machine is protected.

## Repository Layout

| Path | Purpose |
| --- | --- |
| `main/blueshellctl.ps1` | Active command entrypoint and CLI dispatch |
| `main/protocol-state.ps1` | Pure protocol states, transitions, and persistence |
| `main/network.ps1` | Firewall, DNS, and adapter operations |
| `main/bootstrap.ps1` | Initial machine bootstrap and bootstrap state |
| `main/registry.ps1` | Windows registry security hardening |
| `main/wsl.ps1` | WSL installation and network setup |
| `main/logging.ps1` | Agent logs and inspection workflow |
| `main/sandbox.ps1` | Sandbox-related operations |
| `main/hardening.ps1` | Main hardening workflow |
| `etc/` | Supplemental standalone PowerShell utilities |
| `raw/` | Complete original raw script collection; reference material only |
| `tests/` | Platform-independent smoke tests |

Ad hoc WSL and proxy example configurations are maintained outside this
repository so the active project stays focused on the protocol and its
security modules.

Historical duplicate implementations have been removed from `main/previous`.
The original scripts under `raw/` are preserved in full and are not loaded by
the active CLI automatically.

## Running The CLI

Run from an elevated PowerShell session. The active modules perform privileged
operations and can change firewall, adapter, registry, WSL, and local-user
configuration.

```powershell
& .\main\blueshellctl.ps1 help
& .\main\blueshellctl.ps1 protocol-status
& .\main\blueshellctl.ps1 protocol-transition Start
```

The protocol transition command accepts one event at a time:

```powershell
& .\main\blueshellctl.ps1 protocol-transition PolicyApplied
& .\main\blueshellctl.ps1 protocol-transition VerificationPassed
```

Do not run scripts from `raw/` against a production machine without reviewing
them first. Several are intentionally experimental or destructive utilities.

## Validation

The smoke test is the supported first-run verification. It tests the protocol
engine and persistence contract, not live firewall, adapter, registry, WSL, or
logging behavior:

```powershell
pwsh -NoProfile -File .\tests\protocol-state.tests.ps1
```

It verifies initial state creation, valid transitions, invalid-transition
rejection, and JSON round-tripping.

The privileged CLI is a separate manual step. The active entrypoint requires
an elevated PowerShell session and loads its code modules relative to
`main/blueshellctl.ps1`. It stores runtime state under
`C:\Program Files\Blueshellctl`. Do not use the CLI as the first checkout
test, because its network and hardening commands can change the host.

## Development Direction

The next protocol increment is to put network policy application behind the
`Assessing -> Enforcing` transition and require a real verification result
before entering `Protected`. Each side-effect module should eventually expose
three separate operations: inspect current state, apply an idempotent change,
and verify the resulting security property.
