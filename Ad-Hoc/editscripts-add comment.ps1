$lines = Get-Content C:\test1\txt.txt

ForEach ($line in $lines) 
    {
    $i++
    $line.TrimEnd(" ")
    if ($line){ 
        
       Write-host "$($line)number is $i"}
 }

        #$b= ($a.tostring()).Insert(5,"#")     "ST1234567".Insert(2,"0")