$pw = Read-Host "Password" -AsSecureString
New-LocalUser -Name "username" -Password $pw -FullName "User Name"

Add-LocalGroupMember -Group "Administrators" -Member "username"

# check addition
Get-LocalGroupMember Administrators