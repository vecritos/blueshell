function Initialize-SystemDiskPartitions {
    [CmdletBinding(
        SupportsShouldProcess = $true,
        ConfirmImpact = 'High'
    )]
    param (
        # Percentages must add up to 100
        [ValidateRange(1,99)]
        [int]$WindowsPercent = 40,

        [ValidateRange(1,99)]
        [int]$SwapPercent = 15,

        [ValidateRange(1,99)]
        [int]$OtherPercent = 45,

        # Skip interactive confirmation
        [switch]$Force
    )

    Write-Host "Starting disk partitioning..."

    if (($WindowsPercent + $SwapPercent + $OtherPercent) -ne 100) {
        throw "Partition percentages must add up to 100."
    }

    $disk = Get-Disk | Where-Object IsSystem -eq $true
    if (-not $disk) {
        throw "System disk not found. Aborting partition step."
    }

    $diskNumber = $disk.Number
    $totalSize  = $disk.Size

    Write-Host "System disk found: Number $diskNumber, Size $([math]::Round($totalSize / 1GB, 2)) GB"

    $totalMB = [math]::Floor($totalSize / 1MB)
    $winMB   = [math]::Floor($totalMB * ($WindowsPercent / 100))
    $swapMB  = [math]::Floor($totalMB * ($SwapPercent / 100))
    $otherMB = $totalMB - $winMB - $swapMB

    Write-Host "Partition sizes (MB): Windows=$winMB, Swap=$swapMB, Other=$otherMB"

    if (-not $Force) {
        $confirm = Read-Host "WARNING: This will DELETE ALL partitions on disk $diskNumber! Type YES to continue"
        if ($confirm -ne "YES") {
            Write-Host "Aborted partitioning."
            return
        }
    }

    if ($PSCmdlet.ShouldProcess("Disk $diskNumber", "Clear, initialize GPT, and create partitions")) {

        Clear-Disk -Number $diskNumber -RemoveData -Confirm:$false
        Initialize-Disk -Number $diskNumber -PartitionStyle GPT

        Write-Host "Creating Windows partition..."
        $winPartition = New-Partition `
            -DiskNumber $diskNumber `
            -Size ($winMB * 1MB) `
            -AssignDriveLetter

        Format-Volume `
            -Partition $winPartition `
            -FileSystem NTFS `
            -NewFileSystemLabel "Windows" `
            -Confirm:$false

        Write-Host "Creating Swap partition..."
        $swapPartition = New-Partition `
            -DiskNumber $diskNumber `
            -Size ($swapMB * 1MB) `
            -AssignDriveLetter

        Format-Volume `
            -Partition $swapPartition `
            -FileSystem NTFS `
            -NewFileSystemLabel "Swap" `
            -Confirm:$false

        Write-Host "Creating Other partition..."
        $otherPartition = New-Partition `
            -DiskNumber $diskNumber `
            -Size ($otherMB * 1MB) `
            -AssignDriveLetter

        Format-Volume `
            -Partition $otherPartition `
            -FileSystem NTFS `
            -NewFileSystemLabel "Other" `
            -Confirm:$false
    }

    Write-Host "Disk partitioning complete."
}