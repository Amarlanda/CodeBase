$source = "f:\events" 
$destination = "g:\test"

$what = @("/COPYALL","/B","/SEC")
$options = @("/R:0","/W:0","/NFL","/NDL")

$cmdArgs = @("$source","$destination",$what,$options)

$options = '"/COPYALL","/B","/SEC","/R:0","/W:0","/NFL","/NDL","/LOG C:\test\RoboLog.txt"'

robocopy @cmdArgs