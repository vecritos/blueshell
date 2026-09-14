reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\MDM ^
/v DisableEnrollment /t REG_DWORD /d 1 /f

reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\WorkplaceJoin ^
/v BlockAADWorkplaceJoin /t REG_DWORD /d 1 /f