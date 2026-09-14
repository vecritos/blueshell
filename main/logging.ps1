# ==========================================
# Blueshellctl Logging & Secure Log Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
$Script:LogsRoot = Join-Path $Script:BlueshellctlRoot "logs"
$Script:LogsStateFile = Join-Path $Script:BlueshellctlRoot "logs.json"

function Initialize-LogsModule {
    if (-not (Test-Path $Script:LogsRoot)) {
        New-Item -ItemType Directory -Path $Script:LogsRoot -Force | Out-Null
    }
    if (-not (Test-Path $Script:LogsStateFile)) {
        $state = @{ lastOpen = $null; lastInspect = $null; timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss") }
        $state | ConvertTo-Json | Set-Content -Path $Script:LogsStateFile -Encoding UTF8
    }
}

function Get-LogsState {
    Initialize-LogsModule
    Get-Content $Script:LogsStateFile -Raw | ConvertFrom-Json
}

function Set-LogsState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:LogsStateFile -Encoding UTF8
}

function Open-Logs {
    param(
        [string]$LogName = "blueshellctl.log"
    )

    if ([string]::IsNullOrWhiteSpace($LogName)) {
        $LogName = "blueshellctl.log"
    }

    Initialize-LogsModule
    $logPath = Join-Path $Script:LogsRoot $LogName
    if (-not (Test-Path $logPath)) {
        New-Item -Path $logPath -ItemType File | Out-Null
    }

    Write-Host "Opening logs at $logPath" -ForegroundColor Cyan
    Add-Content -Path $logPath -Value "=== Blueshellctl log snapshot: $(Get-Date -Format u) ==="
    Add-Content -Path $logPath -Value "Host: $env:COMPUTERNAME"
    Add-Content -Path $logPath -Value "User: $env:USERNAME"
    Add-Content -Path $logPath -Value ""

    foreach ($eventLog in @("System", "Application")) {
        Add-Content -Path $logPath -Value "--- Recent $eventLog events ---"
        try {
            $records = @(& wevtutil.exe qe $eventLog /c:100 /rd:true /f:text 2>&1)
            if ($LASTEXITCODE -ne 0) {
                throw ($records -join " ")
            }
            Add-Content -Path $logPath -Value "Captured the latest 100 $eventLog records."
            foreach ($record in $records) {
                Add-Content -Path $logPath -Value ([string]$record)
            }
            Write-Host "Captured the latest 100 $eventLog records." -ForegroundColor Green
        } catch {
            Add-Content -Path $logPath -Value "Unable to read $eventLog events: $($_.Exception.Message)"
            Write-Warning "Unable to read $eventLog events: $($_.Exception.Message)"
        }
        Add-Content -Path $logPath -Value ""
    }

    Add-Content -Path $logPath -Value "=== End snapshot ==="
    $state = Get-LogsState
    $state.lastOpen = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-LogsState -State $state
}

function Inspect-Logs {
    param(
        [string]$LogName = "blueshellctl.log",
        [ValidateSet("max","quick")] [string]$ShredMode = "max"
    )

    if ([string]::IsNullOrWhiteSpace($LogName)) {
        $LogName = "blueshellctl.log"
    }

    Initialize-LogsModule
    $logPath = Join-Path $Script:LogsRoot $LogName
    if (-not (Test-Path $logPath)) {
        Write-Warning "$logPath does not exist."
        return
    }

    # Disable network during inspection
    Write-Host "Disabling network adapters for inspection..." -ForegroundColor Yellow
    Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Up"} | Disable-NetAdapter -Confirm:$false

    Write-Host "Entering interactive log inspection for $logPath..."
    Get-Content $logPath | ForEach-Object {
        Write-Host $_
        $null = Read-Host "Press Enter to continue to next line"
    }

    # Shred or zero logs depending on mode
    switch ($ShredMode) {
        "max" {
            Write-Host "Shredding logs with random data..."
            $length = (Get-Item $logPath).Length
            $bytes = New-Object byte[] $length
            (New-Object System.Random).NextBytes($bytes)
            [System.IO.File]::WriteAllBytes($logPath, $bytes)
        }
        "quick" {
            Write-Host "Zeroing out log file quickly..."
            Clear-Content -Path $logPath
        }
    }

    # Update state
    $state = Get-LogsState
    $state.lastInspect = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-LogsState -State $state

    # Re-enable network if needed
    # potential vulnerability to leave more than one adapter up?
    Write-Host "Re-enabling network adapters..." -ForegroundColor Green
    Get-NetAdapter -Physical | Where-Object {$_.Status -eq "Disabled"} | Enable-NetAdapter -Confirm:$false
}

