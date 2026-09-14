# ===== CONFIG =====
$VhdPath = "$env:TEMP\browser_sandbox.vhdx"
$SizeGB = 32

# ===== CREATE =====
New-VHD -Path $VhdPath -SizeBytes (${SizeGB}GB) -Dynamic

# ===== MOUNT + FORMAT =====
Mount-VHD -Path $VhdPath -PassThru | Get-Disk | Initialize-Disk -PartitionStyle GPT -PassThru |
New-Partition -AssignDriveLetter -UseMaximumSize |
Format-Volume -FileSystem NTFS -NewFileSystemLabel "BrowserSandbox" -Confirm:$false

# ===== GET DRIVE =====
$drive = (Get-DiskImage -ImagePath $VhdPath | Get-Disk | Get-Partition | Get-Volume).DriveLetter + ":"

# ===== PROFILE =====
$profilePath = "$drive\BrowserProfile"
New-Item -ItemType Directory -Path $profilePath -Force | Out-Null

# ===== LAUNCH EDGE =====
Start-Process "msedge.exe" "--user-data-dir=$profilePath --no-first-run"

Write-Host "Sandbox running at $drive"
Write-Host "Run teardown when finished."
