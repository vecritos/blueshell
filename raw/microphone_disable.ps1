# Run as Administrator

# Get all audio input devices (microphones)
$microphones = Get-PnpDevice -Class AudioEndpoint | Where-Object { $_.FriendlyName -like "*microphone*" }

foreach ($mic in $microphones) {
    Write-Host "Disabling:" $mic.FriendlyName
    Disable-PnpDevice -InstanceId $mic.InstanceId -Confirm:$false
}

Write-Host "All microphones have been disabled."