# Listen for processes running with elevated privileges
Register-WmiEvent -Query "SELECT * FROM Win32_ProcessStartTrace" -SourceIdentifier "ElevatedProcess" -Action {
    $process = $Event.SourceEventArgs.NewEvent
    $procHandle = Get-Process -Id $process.ProcessID
    $procUser = (Get-WmiObject Win32_Process -Filter "ProcessId=$($process.ProcessID)").GetOwner()
    if ($procUser.User -eq "SYSTEM" -or $procUser.User -eq "Administrator") {
        [System.Windows.Forms.MessageBox]::Show("ALERT: Elevated privileges detected for $($process.ProcessName)","Privilege Alert")
    }
}