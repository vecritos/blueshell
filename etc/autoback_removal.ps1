# cleanup-backup-wifi.ps1

# --- Step 1: Remove scheduled task ---
$taskName = "BackupOnHomeWiFiTest"
if (Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue) {
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    Write-Output "Scheduled task '$taskName' removed."
} else {
    Write-Output "Scheduled task '$taskName' not found."
}

# --- Step 2: Remove generated scripts ---
$backupScriptDir = "C:\Scripts"

if (Test-Path $backupScriptDir) {
    Remove-Item -Path $backupScriptDir -Recurse -Force
    Write-Output "Script folder '$backupScriptDir' deleted."
} else {
    Write-Output "Script folder '$backupScriptDir' not found."
}

# --- Step 3: Optional log cleanup ---
$logFile = "C:\wifi_backup_log.txt"
if (Test-Path $logFile) {
    Remove-Item -Path $logFile -Force
    Write-Output "Log file '$logFile' deleted."
} else {
    Write-Output "Log file '$logFile' not found."
}

Write-Output "Cleanup complete."
