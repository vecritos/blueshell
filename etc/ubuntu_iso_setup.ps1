# -------------------------------
# PowerShell Script: Ubuntu ISO UEFI Boot Setup
# -------------------------------

# --- CONFIGURE THESE VARIABLES ---
$PartitionLetter = "X"              # Letter of your new FAT32 partition (15GB)
$UbuntuISOPath = "C:\Users\You\Downloads\ubuntu.iso"  # Path to your Ubuntu ISO
$GRUBEFIFileName = "BOOTX64.EFI"    # Name of GRUB EFI file
# -------------------------------

# Mount the EFI System Partition (ESP)
$ESP = "S:"
mountvol $ESP /s

# Create EFI\BOOT folder on your ISO partition
$BootFolder = "$PartitionLetter`:\EFI\BOOT"
if (-Not (Test-Path $BootFolder)) {
    New-Item -Path $BootFolder -ItemType Directory -Force
}

# Copy grubx64.efi from mounted Ubuntu ISO (assuming EFI loader exists)
# Mount Ubuntu ISO
$ISOMount = Mount-DiskImage -ImagePath $UbuntuISOPath -PassThru | Get-Volume
$ISOPath = ($ISOMount.DriveLetter + ":\EFI\BOOT\grubx64.efi")
Copy-Item -Path $ISOPath -Destination "$BootFolder\$GRUBEFIFileName" -Force

# Copy ISO to root of partition
Copy-Item -Path $UbuntuISOPath -Destination "$PartitionLetter`:\linux.iso" -Force

# Create minimal grub.cfg
$GrubCfg = @"
set timeout=5
set default=0

menuentry "Boot Ubuntu ISO" {
    search --file --no-floppy --set=root /linux.iso
    set isofile="/linux.iso"
    loopback loop \$isofile
    linux (loop)/casper/vmlinuz boot=casper iso-scan/filename=\$isofile quiet splash ---
    initrd (loop)/casper/initrd
}
"@

$GrubCfgPath = "$BootFolder\grub.cfg"
Set-Content -Path $GrubCfgPath -Value $GrubCfg -Encoding ASCII

# --- Add new UEFI boot entry pointing to GRUB EFI ---
# Create new boot entry
$GUID = bcdedit /create /d "Ubuntu ISO Boot" /application bootsector | ForEach-Object { ($_ -match "{.*}") ; $Matches[0] }

# Set device and path
bcdedit /set $GUID device partition=$PartitionLetter`:
bcdedit /set $GUID path \EFI\BOOT\$GRUBEFIFileName

# Set this entry as first in boot order
bcdedit /displayorder $GUID /addfirst

Write-Output "Ubuntu ISO boot entry created successfully."
Write-Output "Reboot your PC and it should boot the ISO automatically."
