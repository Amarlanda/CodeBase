$data= @()

$hosts =  $((Import-Csv c:\amar\HostToQuery.csv ))

Foreach ($Password in $(cat c:\amar\Passwords.txt )) {
   foreach ($VMhost in $hosts ){

      write-host "trying Server $($VMhost.'server name') with $password"
      Connect-VIServer -server $($VMhost.'ip') -User "root" -pass $password 
      $Data = ($global:DefaultVIServers)| Select *, @{n='Hostname';e={$VMhost.'server name'}}, @{n='RootPass';e={$CurrentPassword}}, @{n='VMs';e={(get-vm | select name)-join ", " }}
      #$hosts =$hosts | ? { $($_.'server name') -ne "$($vmhost.'server name')" }
      Disconnect-VIServer -Server $($VMhost.name) -Confirm:$false 

   }
} 
