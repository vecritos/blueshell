# ==========================================
# Blueshellctl Bootstrap Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
$Script:BootstrapStateFile = Join-Path $Script:BlueshellctlRoot "bootstrap.json"

function Initialize-Bootstrap {
    if (-not (Test-Path $Script:BlueshellctlRoot)) {
        New-Item -ItemType Directory -Path $Script:BlueshellctlRoot -Force | Out-Null
    }
    if (-not (Test-Path $Script:BootstrapStateFile)) {
        $state = @{ completed = $false; timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss") }
        $state | ConvertTo-Json | Set-Content -Path $Script:BootstrapStateFile -Encoding UTF8
    }
}

function Get-BootstrapState {
    Initialize-Bootstrap
    Get-Content $Script:BootstrapStateFile -Raw | ConvertFrom-Json
}

function Set-BootstrapState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:BootstrapStateFile -Encoding UTF8
}

function Invoke-Bootstrap {
    Write-Host "Starting Blueshellctl Bootstrap..." -ForegroundColor Cyan

    # Disk prep prompt
    $resize = Read-Host "Enter size in MB to shrink C: drive for swap/WSL (0 to skip)"
    if ([int]$resize -gt 0) {
        Write-Host "Shrinking C: by $resize MB..."
        # Example: placeholder for real shrink
        # Resize-Partition -DriveLetter C -Size ((Get-Partition -DriveLetter C).Size - ($resize*1MB))
        Write-Host "(Disk shrink simulated)"
    }

    # Create local user
    $username = Read-Host "Enter local admin username"
    $password = Read-Host "Enter password for $username" -AsSecureString
    if (-not (Get-LocalUser -Name $username -ErrorAction SilentlyContinue)) {
        New-LocalUser -Name $username -Password $password -FullName $username -Description "Blueshellctl local admin"
        Add-LocalGroupMember -Group "Administrators" -Member $username
        Write-Host "Local admin user $username created."
    } else {
        Write-Host "User $username already exists."
    }

    # BYPASSNRO placeholder
    Write-Host "Applying BYPASSNRO for login screen..." -ForegroundColor Yellow
    # Real bypass logic would be implemented here

    # Mark bootstrap completed
    $state = Get-BootstrapState
    $state.completed = $true
    $state.timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-BootstrapState -State $state

    # Network lockdown after bootstrap
    Write-Host "Disabling network adapters for security post-bootstrap..." -ForegroundColor Red
    # Disable-NetAdapter -Name "*" -Confirm:$false -PassThru | Where-Object {$_.Status -eq "Up"}

    Write-Host "Bootstrap completed." -ForegroundColor Green
}

