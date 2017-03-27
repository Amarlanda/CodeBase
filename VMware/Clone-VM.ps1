$vms = get-vm                     ## get-vm
$poweroffVM = cat .\Vms.txt          ## stop-vm
$targetVMs = @{}


 $vms | % {                                           ##stop VM
  $currentvm = $_ 
  $poweroffVM | % { 
    if (($($currentvm.name) -eq "$($_)") -and (-not($($currentvm.name).Endswith("F")))){  
              
     if ($currentvm.powerstate -eq "poweredon" ) { $currentvm | stop-vm -confirm:$false -runasync
     $targetVMs.add($currentvm.name, $currentvm)
     Write-Host "powering off VM $($currentvm)"
     }
     $clonevm = get-vm -name $($currentvm.name)

     if ($clonevm.count -eq 1){
     Write-host "will clone this VM $($clonevm.name)" -ForegroundColor Green
     $clonevm.count
     $string = "$($clonevm.name)" + "F"
     
     get-datastore | ? { $_.name -like "*Pool2*" }| ? { $_.freespaceMB -gt 180000 } | Get-Random | % {
     new-vm -name $string -vm $clonevm -vmhost $(get-vmhost -name ukdcavdi006.uk.kworld.kpmg.com) -Datastore $($_) -location $(get-folder -name "Audit Live Full Clones" ) -diskstorageformat thin -runasync }
     } else {
     # Write-host "Duplicate VM $clonevm.name" -ForegroundColor Gray
     
     }

     } 
  }
 } 