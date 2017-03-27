$vms =  Get-Datacenter -name "UKIXEVDKGS02"|  get-vm | sort Asecending
$vms = $vms | ? {(($_ | Get-view ).config.hardware.numcorespersocket -ne "2")}
#$vms | % { shutdown-vmguest -vm $_ -confirm:$false}

$corecount =2
$proccount =2

$spec = new-object -typename VMware.VIM.virtualmachineconfigspec -property @{'numcorespersocket'=$corecount;'numCPUs'=$($proccount * $corecount)}

$vms | % { 
  #if (($_ | Get-view ).config.hardware.numcorespersocket -notlike "2" ){
    

    (Get-VM –Name $_.name).ExtensionData.ReconfigVM_Task($spec)
	write "changed $_.name "
   }