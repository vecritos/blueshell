$Target = "example.com"
$BaselineFile = ".\route_baseline_ultra.json"
$LatencySpikeMs = 80
$JitterThreshold = 40
$EnableEmail = $false

# Optional email config
$SmtpServer = "smtp.yourserver.com"
$From = "alert@domain.com"
$To = "you@domain.com"

function Get-HopTrace {
    param($Target)

    $trace = Test-NetConnection $Target -TraceRoute

    $trace.TraceRoute | ForEach-Object {
        $ptr = "No PTR"
        try {
            $dns = Resolve-DnsName $_.Address -ErrorAction Stop
            $ptr = $dns.NameHost
        } catch {}

        $asn = Get-ASN $_.Address

        [PSCustomObject]@{
            Hop = $_.Hop
            IP = $_.Address
            Name = $ptr
            RTT = [int]$_.ResponseTime
            ASN = $asn
        }
    }
}

function Get-ASN {
    param($IP)

    try {
        $whois = nslookup -type=txt "$IP.origin.asn.cymru.com" 2>$null
        $line = $whois | Select-String "origin"
        if ($line) {
            return ($line -split '"')[1]
        }
    } catch {}

    return "Unknown"
}

function Get-RouteFingerprint {
    param($Route)

    $string = ($Route.IP -join "-")
    $bytes = [System.Text.Encoding]::UTF8.GetBytes($string)
    $sha = [System.Security.Cryptography.SHA256]::Create()
    $hash = $sha.ComputeHash($bytes)
    return ([BitConverter]::ToString($hash)).Replace("-", "")
}

function Get-Jitter {
    param($Route)

    $rtts = $Route.RTT
    if ($rtts.Count -lt 2) { return 0 }

    $differences = @()
    for ($i=1; $i -lt $rtts.Count; $i++) {
        $differences += [math]::Abs($rtts[$i] - $rtts[$i-1])
    }

    return ($differences | Measure-Object -Average).Average
}

function Send-Alert {
    param($Message)

    if ($EnableEmail) {
        Send-MailMessage -SmtpServer $SmtpServer `
                         -From $From `
                         -To $To `
                         -Subject "Hop Anomaly Alert" `
                         -Body $Message
    }
}

Write-Host "`n=== Ultra Hop Inspection: $Target ===`n"

$current = Get-HopTrace -Target $Target
$fingerprint = Get-RouteFingerprint $current
$jitter = Get-Jitter $current

# First run
if (-not (Test-Path $BaselineFile)) {
    Write-Host "No baseline found — creating baseline." -ForegroundColor Yellow
    $baselineObj = @{
        Route = $current
        Fingerprint = $fingerprint
    }
    $baselineObj | ConvertTo-Json -Depth 5 | Set-Content $BaselineFile
    return
}

$baselineObj = Get-Content $BaselineFile | ConvertFrom-Json
$baseline = $baselineObj.Route
$baselineFingerprint = $baselineObj.Fingerprint

# Compare routes
$diff = Compare-Object $baseline $current -Property IP

# Latency spike detection
$latencyFindings = $current | Where-Object {
    $_.RTT -gt $LatencySpikeMs
}

# Jitter detection
$jitterFlag = $jitter -gt $JitterThreshold

# Fingerprint change
$fingerprintChanged = $fingerprint -ne $baselineFingerprint

# Risk Scoring
$risk = 0
if ($fingerprintChanged) { $risk += 40 }
if ($diff) { $risk += 20 }
if ($latencyFindings) { $risk += 20 }
if ($jitterFlag) { $risk += 20 }

# Output
$current | Format-Table -AutoSize

Write-Host "`nRoute Fingerprint: $fingerprint"
Write-Host "Jitter Avg: $([math]::Round($jitter,2)) ms"

if ($fingerprintChanged) {
    Write-Host "`n⚠ Route fingerprint changed" -ForegroundColor Red
}

if ($diff) {
    Write-Host "`n⚠ Hop differences detected" -ForegroundColor Red
    $diff | Format-Table
}

if ($latencyFindings) {
    Write-Host "`n⚠ Latency spikes detected" -ForegroundColor Yellow
    $latencyFindings | Format-Table
}

if ($jitterFlag) {
    Write-Host "`n⚠ High jitter detected" -ForegroundColor Yellow
}

Write-Host "`n=== Risk Score: $risk / 100 ===`n"

if ($risk -ge 60) {
    Send-Alert "High route anomaly risk detected ($risk/100)"
}