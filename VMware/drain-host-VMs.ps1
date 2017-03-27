$UsedVMs = @{}
$sourcehost = "ukdcavdi033.uk.kworld.kpmg.com"
set-vmhost -vmhost $sourcehost -state "maintenance" -RunAsync

$vmhosts = Get-Cluster | % { 
  $clustername = $_.name
  $_ | get-vmhost | select *, @{n='Clustername';e={$clustername}}
  } | Group-Object clustername | ? { $_.count -gt 1} 

## get randon VMs



Get-vm | ? { $_.vmhost -like "$currenthost"} | Sort-Object { [Guid]::NewGuid() } | % { $UnUsedVMs.add( $_.name, $_) }

$(($vmhosts | Group-Object clustername | ? { $_.count -gt 1})[0].group).name | % {

  $CurrentEsxHost =  $_
  
  if ($sourcehost -ne $CurrentEsxHost){
    get-vmhost -name $sourcehost | get-vm |Select -first 1 | % { 
    $UsedVMs.add( $_.name, $_)
        
    move-vm -vm $_ -destination $CurrentEsxHost -runasync
    break
    }
  }
 }
    

