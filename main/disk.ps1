# ==========================================
# Disk Management Module
# ==========================================

$Script:BlueshellctlRoot = Join-Path ${env:ProgramFiles} "Blueshellctl"
$Script:DiskStateFile = Join-Path $Script:BlueshellctlRoot "disk.json"

# -------------------------------
# Initialize Disk State
# -------------------------------
function Initialize-DiskState {
    if (-not (Test-Path $Script:DiskStateFile)) {
        $state = @{
            ntfsShrunk = $false
            linuxPartitionCreated = $false
            swapCreated = $false
            lastRun = ""
        }
        $state | ConvertTo-Json | Set-Content -Path $Script:DiskStateFile -Encoding UTF8
    }
}

function Get-DiskState {
    Initialize-DiskState
    Get-Content $Script:DiskStateFile -Raw | ConvertFrom-Json
}

function Set-DiskState {
    param([Parameter(Mandatory)][object]$State)
    $State | ConvertTo-Json | Set-Content -Path $Script:DiskStateFile -Encoding UTF8
}

# -------------------------------
# Shrink NTFS Volume
# -------------------------------
function Invoke-DiskShrink {
    param(
        [Parameter(Mandatory)]
        [string]$DriveLetter,
        [Parameter(Mandatory)]
        [int]$ShrinkMB
    )

    Write-Host "Shrinking $DriveLetter by $ShrinkMB MB..." -ForegroundColor Cyan
    $volume = Get-Volume -DriveLetter $DriveLetter
    if (-not $volume) { Write-Error "Drive $DriveLetter not found"; return }

    $disk = Get-Disk -Number $volume.DiskNumber
    $sizeBytes = $ShrinkMB * 1MB
    Resize-Partition -DiskNumber $disk.Number -PartitionNumber $volume.PartitionNumber -Size ($volume.Size - $sizeBytes)

    $state = Get-DiskState
    $state.ntfsShrunk = $true
    $state.lastRun = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-DiskState -State $state
    Write-Host "NTFS shrink completed." -ForegroundColor Green
}

# -------------------------------
# Create Linux Partition
# -------------------------------
function Invoke-LinuxPartition {
    param(
        [Parameter(Mandatory)]
        [int]$SizeMB
    )

    Write-Host "Creating Linux partition of $SizeMB MB..." -ForegroundColor Cyan
    $disk = Get-Disk | Where-Object { $_.PartitionStyle -eq "GPT" } | Select-Object -First 1
    if (-not $disk) { Write-Error "No GPT disk found"; return }

    $partition = New-Partition -DiskNumber $disk.Number -UseMaximumSize:$false -Size ($SizeMB * 1MB) -AssignDriveLetter
    Format-Volume -Partition $partition -FileSystem ext4 -Force

    $state = Get-DiskState
    $state.linuxPartitionCreated = $true
    $state.lastRun = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
    Set-DiskState -State $state
    Write-Host "Linux partition created on drive $($partition.DriveLetter)." -ForegroundColor Green
}

# -------------------------------
# Create Temporary Partition
# -------------------------------
Write-Host "Temporary Paritition Setup is not implemented, please add this functionality"
# function Invoke-SwapSetup {
#     param(
#         [Parameter(Mandatory)]
#         [int]$SwapMB
#     )
# 
#     $swapPath = "C:\swapfile.sys"
#     Write-Host "Creating swap file of $SwapMB MB at $swapPath..." -ForegroundColor Cyan
# 
#     fsutil file createnew $swapPath ($SwapMB * 1MB)
#     # Enable paging file
#     wmic pagefileset where name="$swapPath" delete
#     wmic pagefileset create name="$swapPath"
# 
#     $state = Get-DiskState
#     $state.swapCreated = $true
#     $state.lastRun = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
#     Set-DiskState -State $state
#     Write-Host "Swap file created." -ForegroundColor Green
# }
