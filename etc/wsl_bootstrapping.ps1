# =========================================
# Hyper-V + WSL Git Sandbox Bootstrap Script
# =========================================
# WARNING: Run as Administrator
# =========================================

# --------------------------
# 1. Enable Hyper-V
# --------------------------
Write-Host "Enabling Hyper-V..."
Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Hyper-V -All -NoRestart

# --------------------------
# 2. Create External Virtual Switch
# --------------------------
$SwitchName = "GitSandboxSwitch"
$ExternalNIC = Get-NetAdapter | Where-Object {$_.Status -eq "Up"} | Select-Object -First 1

if (-Not (Get-VMSwitch -Name $SwitchName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating external virtual switch: $SwitchName"
    New-VMSwitch -Name $SwitchName -NetAdapterName $ExternalNIC.Name -AllowManagementOS $false
} else {
    Write-Host "Switch $SwitchName already exists."
}

# --------------------------
# 3. Create Hyper-V VM
# --------------------------
$VMName = "GitSandboxVM"
$VHDPath = "C:\HyperV\$VMName\$VMName.vhdx"
$ISOPath = "C:\ISO\ubuntu-22.04-live-server-amd64.iso"  # Change path to your Ubuntu ISO

if (-Not (Get-VM -Name $VMName -ErrorAction SilentlyContinue)) {
    Write-Host "Creating VM: $VMName"
    New-VM -Name $VMName -MemoryStartupBytes 2GB -Generation 2 -NewVHDPath $VHDPath -NewVHDSizeBytes 20GB -SwitchName $SwitchName

    Set-VMFirmware -VMName $VMName -EnableSecureBoot On

    # Attach ISO for installation
    Add-VMDvdDrive -VMName $VMName -Path $ISOPath

    # Optional: enable checkpoints
    Set-VM -VMName $VMName -CheckpointType Production
} else {
    Write-Host "VM $VMName already exists."
}

# --------------------------
# 4. Start VM
# --------------------------
Write-Host "Starting VM..."
Start-VM -Name $VMName

# --------------------------
# 5. Create inside-VM Git setup script
# --------------------------
$InsideScript = @"
#!/bin/bash
# --------------------------
# Git Sandbox Setup Script (inside VM)
# --------------------------
sudo adduser gituser
sudo usermod -aG sudo gituser

# Disable root login over SSH
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install essentials
sudo apt update
sudo apt full-upgrade -y
sudo apt install -y git ufw iptables-persistent curl

# Firewall default deny
sudo ufw default deny incoming
sudo ufw default deny outgoing
sudo ufw allow in on lo
sudo ufw allow out on lo
sudo ufw allow out 53
sudo ufw allow out 443/tcp
sudo ufw enable

# Git wrapper
sudo bash -c 'cat <<EOF > /usr/local/bin/git-safe
#!/usr/bin/env bash
allowed_regex="github.com"
if [[ "\$*" =~ \$allowed_regex ]]; then
    exec /usr/bin/git "\$@"
else
    echo "Blocked: remote not allowed"
    exit 1
fi
EOF'
sudo chmod +x /usr/local/bin/git-safe

echo 'alias git=/usr/local/bin/git-safe' >> /home/gituser/.bashrc

# Remove unnecessary packages
sudo apt purge -y telnet ftp netcat* nmap avahi-daemon cups snapd
sudo apt autoremove -y

echo "Git sandbox setup complete. Login as gituser."
"@

$ScriptPath = "C:\HyperV\$VMName\git_sandbox_setup.sh"
$InsideScript | Out-File -FilePath $ScriptPath -Encoding ASCII
Write-Host "Inside-VM Git setup script saved to $ScriptPath"
Write-Host "After installing Ubuntu in the VM, copy this script inside and run: bash git_sandbox_setup.sh"

# --------------------------
# 6. Optional: WSL setup commands
# --------------------------
$WSLCommands = @"
# Enable WSL (optional)
wsl --install -d Ubuntu
wsl --set-default-version 2

# WSL Git containment (manual)
# Run inside WSL:
# Copy the same git_sandbox_setup.sh commands as above
"@
Write-Host $WSLCommands
