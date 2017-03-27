$vms | % { 
  if (($_ | Get-view ).config.hardware.numcorespersocket -notlike "2" ){
     Shutdown-VMGuest -vm $_.name -Confirm:$false
    (Get-VM –Name $_.name).ExtensionData.ReconfigVM_Task($spec)
    Write-Host "$_.name reconfigured"
    Start-vm -vm $_.name -Confirm:$false

   }
    
}
