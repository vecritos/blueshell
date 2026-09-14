reg add HKLM\SOFTWARE\Policies\Microsoft\Windows\System ^
/v DisableAadCloudAPPlugin /t REG_DWORD /d 1 /f

reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\UserProfileEngagement ^
/v ScoobeSystemSettingEnabled /t REG_DWORD /d 0 /f