$pingConfig = @{

"count" = 1

"bufferSize" = 15

"delay" = 1

"EA" = 0 }

$property =  "Systemname", "numberOfCores", "NumberOfLogicalProcessors"
$computer =@()
             
Cat c:\test\vms.txt | % {          
               

    if(Test-Connection -ComputerName $_ @pingconfig){
         
          Get-WmiObject Win32_Processor -computername $_  |

         Select-Object -Property $property 

         }

         Else {
         Write-host "Please check $_ manually"
         }
} 

write-host "sdfsd $computer"
         
         
     


