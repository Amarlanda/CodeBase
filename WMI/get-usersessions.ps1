$computers =@"
ukpk1naxp
ukpk1naxp
ukpk1naxp
ukr9zm1y0
ukpk1naxp
ukpk0yvlp
ukpk1naxp
ukpk1naxp
ukpk1naxp
ukpk1naxp
ukpk1naxp
ukr9ytnlg
ukpk1naxp
ukr9ytnlg
UKPK0DBHB
ukpk1naxp
ukr9ytnlg
ukpk1naxp
ukr9ytnlg
ukpk1naxp
ukr9ytnlg
ukpk1naxp
ukr9ytnlg
ukpk1naxp
ukr9ytnlg
ukpk26m4d
ukr9ytnlg
ukpk26m4d
ukr9ytnlg
ukpk1k15p
"@
#>

$machineusers = "SYSTEM", "NETWORK SERVICE", "LOCAL SERVICE"

$Res = $computers.Split().trim(" ") | select -Unique | % {  Get-WmiObject -class win32_process -ComputerName $_  } 



$Res | select-object @{n='Name';e={ $_.PSComputerName }},
Processname, Procname, @{n='User';e={ $_.getowner().user }} |
? { $_.user -notin $machineusers } | select -unique user, name | Export-Csv C:\test\logegdinusers.csv -NoTypeInformation