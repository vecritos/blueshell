# Calculate and show SHA256 of this script file
$CurrentDate = (Get-Date).ToString("yyyy-MM-dd")
$SeenIPs = [System.Collections.Generic.HashSet[string]]::new()

while ($true) {

    $NowDate = (Get-Date).ToString("yyyy-MM-dd")

    # If the day changed, reset tracking
    if ($NowDate -ne $CurrentDate) {
        $CurrentDate = $NowDate
        $SeenIPs.Clear()
    }

    Clear-Host

    $connections =
        Get-NetTCPConnection |
        Where-Object { $_.State -eq "Established" -and $_.RemoteAddress -notlike "127.*" } |
        ForEach-Object {
            $p = Get-Process -Id $_.OwningProcess -ErrorAction SilentlyContinue
            if ($p) {
                # Track unique IPs for the day
                $SeenIPs.Add($_.RemoteAddress) | Out-Null

                [PSCustomObject]@{
                    Process = $p.ProcessName
                    IP      = $_.RemoteAddress
                }
            }
        } |
        Sort-Object Process, IP -Unique

    # Display live table
    $ScriptPath = $MyInvocation.MyCommand.Path
    if ($ScriptPath) {
        $hash = Get-FileHash -Path $ScriptPath -Algorithm SHA256
        Write-Host "SHA256:" $hash.Hash
    } else {
        Write-Host "Script path not found; cannot calculate hash."
    }
    
    $connections | Format-Table -AutoSize

    # Write daily unique IPs to file
    $LogFile = "$PSScriptRoot\network_ips_$CurrentDate.txt"
    $SeenIPs | Sort-Object | Set-Content $LogFile

    Start-Sleep 5
}
