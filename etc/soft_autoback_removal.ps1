# disable-backup-task.ps1

$taskName = "BackupOnHomeWiFiTest"

# Check if the scheduled task exists
$task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue

if ($task) {
    # Disable the task
    Disable-ScheduledTask -TaskName $taskName
    Write-Output "Scheduled task '$taskName' has been disabled."

    # Optional: remove completely (comment out if you just want to disable)
    # Unregister-ScheduledTask -TaskName $taskName -Confirm:$false
    # Write-Output "Scheduled task '$taskName' has been removed."
} else {
    Write-Output "Scheduled task '$taskName' not found."
}

Write-Output "Soft cleanup complete. Scripts and log files remain untouched."
