#$computers= "ukwatsrv126", "ukwatsrv127", "ukwatsrv128", "ukwatsrv129" 



$Computers = @"
UKVMAPP015
UKVMAPP001
UKWATAPP181
UKWATSRV134
UKWATWTS154
UKWATWTS164
ukdtavsh036
UKWATVSH202
UKWATVSH203
"@

$computers.split(",", [StringSplitOptions]::RemoveEmptyEntries).TRIM( ) | % { 
#}
 # REMOVE TO TEST write-host "a $_ a"}                                                   
 # REMOVE TO TEST $(($Computers -split '[\r\n]') |? {$_} )| % {                           
Test-Connection -Cn $_ -Count 1  } |select Address ,IPv4address, ResponseTime, TimeToLive 

