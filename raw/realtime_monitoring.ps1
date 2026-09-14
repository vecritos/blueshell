Register-WmiEvent `
  -Query "SELECT * FROM Win32_NTLogEvent WHERE Logfile='Security' AND (EventCode=5156 OR EventCode=5157)" `
  -Action { Write-Host "Network event detected" }