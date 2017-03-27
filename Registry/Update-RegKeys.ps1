Set-Location "HKLM:\SYSTEM\Setup\Status\SysprepStatus"

Set-ItemProperty -path. -name "cleanupstate" -value "2"
Set-ItemProperty -path. -name "GeneralizationState" -value "7"

Set-Location "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform"
Set-ItemProperty -path. -name "skipRearm" -value "1"

Remove-Item "C:\Windows\System32\sysprep\Panther" -Force -Recurse

Start-Process -FilePath "c:\windows\system32\sysprep\sysprep.exe"  -ArgumentList "/generalize /reboot"

Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\SoftwareProtectionPlatform" -name "skipRearm"
Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -name "cleanupstate"
Get-ItemProperty -Path "HKLM:\SYSTEM\Setup\Status\SysprepStatus" -name "GeneralizationState"

