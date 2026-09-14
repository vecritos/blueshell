Stop-Service wlidsvc -Force
Set-Service wlidsvc -StartupType Disabled

Stop-Service dmwappushservice -Force
Set-Service dmwappushservice -StartupType Disabled