$VhdPath = "$env:TEMP\browser_sandbox.vhdx"

Stop-Process -Name msedge -ErrorAction SilentlyContinue
Stop-Process -Name chrome -ErrorAction SilentlyContinue

Dismount-VHD -Path $VhdPath
Remove-Item $VhdPath -Force
