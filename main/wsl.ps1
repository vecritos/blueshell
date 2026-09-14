# ==========================================
# Blueshellctl WSL Installation Module
# ==========================================

# Ensure Admin
if (-not ([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run as Administrator."
    exit 1
}

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
$Script:WSLStateFile = Join-Path $Script:BlueshellctlRoot "wsl.json"

function Initialize-WSLModule {
    if (-not (Test-Path $Script:BlueshellctlRoot)) {
        New-Item -ItemType Directory -Path $Script:BlueshellctlRoot -Force | Out-Null
    }
    if (-not (Test-Path $Script:WSLStateFile)) {
        $state = @{ installed = $false; timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss") }
        $state | ConvertTo-Json | Set-Content -Path $Script:WSLStateFile -Encoding UTF8
    }
}

function Get-WSLState {
    Initialize-WSLModule
    Get-Content $Script:WSLStateFile -Raw | ConvertFrom-Json
}

function Set-WSLState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:WSLStateFile -Encoding UTF8
}

function Invoke-WSLSetup {
    Write-Host "Starting WSL installation and configuration..." -ForegroundColor Cyan

    # Enable WSL feature
    Write-Host "Enabling WSL and Virtual Machine Platform..."
    Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart -All | Out-Null
    Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart -All | Out-Null

    # Install a default distro (Ubuntu)
    $distro = "Ubuntu-22.04"
    if (-not (wsl.exe -l -v | Select-String $distro)) {
        Write-Host "Downloading and installing $distro..."
        # Invoke-WebRequest -Uri "https://aka.ms/wslubuntu2004" -OutFile "$env:TEMP\Ubuntu.appx"
        # Add-AppxPackage "$env:TEMP\Ubuntu.appx"
        wsl --install

        Write-Output "Waiting for $distro to be ready..."
        while ($true) {
            try {
                $output = wsl -d $distro -- echo ready
                if ($output -eq "ready") { break }
            } catch {
                # ignore errors here wait for ready
            }
            Start-Sleep -Seconds 2
        }

        Write-Output "$distro is ready! Running initialization script on distro"

        # hardcoded for now :(
        wsl -d $distro -u root -- bash -c "/mnt/c/Program\ Files/Blueshellctl/wsl_init.sh"
        Write-Host "$distro installed."
    } else {
        Write-Host "$distro is already installed."
    }

    # Configure proxy hops if needed
    $proxyHops = Read-Host "Enter number of proxy hops (0 for direct)"
    if ([int]$proxyHops -gt 0) {
        Write-Host "Configuring $proxyHops proxy hop(s) for WSL networking..."
        # Placeholder: real proxy chain config would go here
        Write-Host "(Proxy chain simulated)"
    }

    # Update state
    $state = Get-WSLState
    $state.installed = $true
    $state.timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-WSLState -State $state

    Write-Host "WSL setup complete." -ForegroundColor Green
    Write-Host "Restart recommended for WSL 2 kernel changes." -ForegroundColor Yellow
}

