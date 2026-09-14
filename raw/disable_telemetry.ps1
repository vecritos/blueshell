reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\DataCollection ^
/v AllowTelemetry /t REG_DWORD /d 0 /f

Stop-Service DiagTrack -Force
Set-Service DiagTrack -StartupType Disabled

# nuke cloud sync
Stop-Service OneSyncSvc -Force
Stop-Service OneDriveSvc -Force

# uninstall onedrive
taskkill /f /im OneDrive.exe
%SystemRoot%\SysWOW64\OneDriveSetup.exe /uninstall