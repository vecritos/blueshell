$Target = "example.com"
$BaselineFile = ".\route_baseline.json"
$LatencySpikeMs = 80

function Get-HopTrace {
    param($Target)

    $trace = Test-NetConnection $Target -TraceRoute

    $trace.TraceRoute | ForEach-Object {
        $ptr = "No PTR"

        try {
            $dns = Resolve-DnsName $_.Address -ErrorAction Stop
            $ptr = $dns.NameHost
        } catch {}

        [PSCustomObject]@{
            Hop = $_.Hop
            IP = $_.Address
            Name = $ptr
            RTT = [int]$_.ResponseTime
        }
    }
}

function Get-RiskScore {
    param($Diff, $LatencyFindings)

    $score = 0

    if ($Diff) { $score += 40 }
    if ($LatencyFindings) { $score += 30 }

    return $score
}

Write-Host "`n=== Hop Inspection: $Target ===`n"

$current = Get-HopTrace -Target $Target

# --- First run creates baseline ---
if (-not (Test-Path $BaselineFile)) {
    Write-Host "No baseline found — creating baseline." -ForegroundColor Yellow
    $current | ConvertTo-Json | Set-Content $BaselineFile
    return
}

$baseline = Get-Content $BaselineFile | ConvertFrom-Json

# --- Compare hops ---
$diff = Compare-Object $baseline $current -Property IP

# --- Latency anomaly detection ---
$latencyFindings = $current | Where-Object {
    $_.RTT -gt $LatencySpikeMs
}

# --- Risk score ---
$risk = Get-RiskScore -Diff $diff -LatencyFindings $latencyFindings

# --- Output ---
Write-Host "Current Route:`n" -ForegroundColor Cyan
$current | Format-Table -AutoSize

if ($diff) {
    Write-Host "`n⚠ Route changes detected:" -ForegroundColor Red
    $diff | Format-Table
} else {
    Write-Host "`n✓ Route matches baseline" -ForegroundColor Green
}

if ($latencyFindings) {
    Write-Host "`n⚠ Latency spikes detected:" -ForegroundColor Yellow
    $latencyFindings | Format-Table
}

Write-Host "`n=== Risk Score: $risk / 100 ===`n"