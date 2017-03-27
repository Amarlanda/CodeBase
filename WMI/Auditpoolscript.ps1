$Computers = @"
UKPK1DX14
"@

Foreach ($comp in $($Computers.split())){
    $comp = $($comp.trim())
    $comp = "\\$comp\c$"

    $task = 'auditpol.exe /set /subcategory:"Process Creation" /success:enable > c:\test\output'

    Copy-Item -Force -path "\\UKVMSWTS001\share\auditpool.ps1" -Destination "\\$comp\Audit\" 
    ([WMIClass]"\\$(hostname)\root\cimv2:Win32_Process").Create($task)


}


