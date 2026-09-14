# bootstrap-backup-wifi-system-dynamic.ps1

# --- Step 1: Scan for Wi-Fi networks ---
Write-Output "Scanning for Wi-Fi networks..."
$wifiList = netsh wlan show networks | Select-String "SSID" | ForEach-Object {
    ($_ -replace "SSID\s+\d+\s*:\s*", "").Trim()
} | Select-Object -Unique

if ($wifiList.Count -eq 0) {
    Write-Output "No Wi-Fi networks found. Exiting."
    exit
}

# --- Step 2: Display numbered list ---
Write-Output "Available Wi-Fi networks:"
for ($i = 0; $i -lt $wifiList.Count; $i++) {
    Write-Output "$($i+1): $($wifiList[$i])"
}

# --- Step 3: Select home Wi-Fi ---
do {
    $selection = Read-Host "Enter the number of your home Wi-Fi network"
} while (-not ($selection -as [int]) -or $selection -lt 1 -or $selection -gt $wifiList.Count)

$selectedSSID = $wifiList[$selection - 1]

# --- Step 4: Prompt for Wi-Fi password (reference only) ---
$password = Read-Host "Enter the Wi-Fi password (for reference; not used for auto-connect)" -AsSecureString
$ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password)
$plainPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)

# --- Step 5: Setup directories and paths ---
$backupScriptDir = "C:\Scripts"
$monitorScriptPath = Join-Path $backupScriptDir "backup-on-wifi-auto.ps1"
$backupScriptPath = Join-Path $backupScriptDir "backup.ps1"
$logFile = "C:\wifi_backup_log.txt"

# Detect current user's Documents folder dynamically
$envUser = $env:USERNAME
$sourceFolder = [Environment]::GetFolderPath("MyDocuments")
$backupDestination = "D:\Backups\Documents"  # default destination

# Create necessary directories if missing
foreach ($dir in @($backupScriptDir, $backupDestination)) {
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
}

# --- Step 6: Generate backup script ---
$defaultBackup = @"
# Auto-generated backup script
`$source = '$sourceFolder'  # User Documents folder
`$destination = '$backupDestination'
`$log = Join-Path `$destination 'backup_details.log'

if (-not (Test-Path `$destination)) { New-Item -ItemType Directory -Path `$destination | Out-Null }

# Mirror backup using Robocopy
Robocopy `$source `$destination /MIR /R:3 /W:5 /LOG:`$log
"@

$defaultBackup | Out-File -FilePath $backupScriptPath -Encoding UTF8
Write-Output "Backup script created at: $backupScriptPath"
Write-Output "Backing up source folder: $sourceFolder"

# --- Step 7: Generate Wi-Fi monitor script with logging ---
$monitorContent = @"
# Auto-generated Wi-Fi backup monitor
`$homeSSID = '$selectedSSID'
`$backupScript = '$backupScriptPath'
`$logFile = '$logFile'
`$backupDestination = '$backupDestination'

while (\$true) {
    try {
        # Get visible SSIDs
        \$currentSSIDs = (netsh wlan show networks) | Select-String 'SSID' | ForEach-Object {
            (\$_ -replace 'SSID\s+\d+\s*:\s*','').Trim()
        }

        if (\$currentSSIDs -contains `$homeSSID) {
            Write-Output "Home Wi-Fi `$homeSSID is in range! Running backup..."
            
            # Ensure backup directories exist
            if (-not (Test-Path `$backupDestination)) { New-Item -ItemType Directory -Path `$backupDestination | Out-Null }
            
            & `$backupScript

            # Log timestamp in yyyyMMddHHmmss
            \$timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            \$timestamp | Out-File -FilePath `$logFile -Encoding UTF8 -Append
            Write-Output "Backup logged at \$timestamp"

            # Wait 5 minutes before next check
            Start-Sleep -Seconds 300
        }
    } catch {
        Write-Output "Error checking Wi-Fi: \$_"
    }
    Start-Sleep -Seconds 60
}
"@

$monitorContent | Out-File -FilePath $monitorScriptPath -Encoding UTF8
Write-Output "Wi-Fi monitor script created at: $monitorScriptPath"

# --- Step 8: Register SYSTEM scheduled task ---
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -WindowStyle Hidden -File `"$monitorScriptPath`""
$trigger = New-ScheduledTaskTrigger -AtStartup
$principal = New-ScheduledTaskPrincipal -UserId "SYSTEM" -RunLevel Highest
Register-ScheduledTask -TaskName "BackupOnHomeWiFiAuto" -Action $action -Trigger $trigger -Principal $principal

Write-Output "Scheduled task 'BackupOnHomeWiFiAuto' created as SYSTEM."
Write-Output "Your backup will now run automatically whenever '$selectedSSID' is in range."
Write-Output "Backup timestamps are logged to $logFile"
