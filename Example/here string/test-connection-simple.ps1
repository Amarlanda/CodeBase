$Computers = @" "

$ping = import-csv C:\amar\PING.csv
$ping

$ping = $ping | select *, ip

$new = $ping | %{

$_.ip = " $((Test-Connection -computername $_.comp -Count 1).IPV4Address.IPAddressToString) "

} 


$new
$ping | export-csv C:\amar\MOping.csv -NoTypeInformation


$computers.split("", [StringSplitOptions]::RemoveEmptyEntries).TRIM( ) | % { $bla = $_; Test-Connection -computername $bla -Count 1 } | select Address ,IPv4address, ResponseTime, TimeToLive | Export-csv c:\amar\bla.csv -NoTypeInformation