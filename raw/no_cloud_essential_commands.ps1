dsregcmd /leave
reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System /v NoConnectedUser /t REG_DWORD /d 3 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM /v DisableEnrollment /t REG_DWORD /d 1 /f
reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection /v AllowTelemetry /t REG_DWORD /d 0 /f