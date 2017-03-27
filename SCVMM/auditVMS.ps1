<#


$PossibleOwners = $hosts  | where HostCluster -like 'UKVMSCLU002.uk.kworld.kpmg.com' | where Name -match 'DCA'

Get-Content TheFile.txt | ForEach-Object {

Write-Host "I am setting owners for $_"

Set-SCVirtualMachine $_ -ClusterNonPossibleOwner $PossibleOwners -WhatIf

}

from virtual machine 

possible owners
hostype 

feed in a VM

pattern matching on the name of the VM
#>

Import-Module virtualmachinemanager

##Get hosts on prod cluster 'UKVMSCLU002.uk.kworld.kpmg.com'
  $hosts =  Get-SCVMHost | Where-Object HostCluster -like 'UKVMSCLU002.uk.kworld.kpmg.com' 

##Populate possible owners for Watford hosts
  Write-Host 'Display WAT hosts' 
  $WATHosts = $hosts | where name -match "DCA"  
   Write-host "amount of hosts $($WATHosts.count)"


##Populate possible owners for IXE hosts
  Write-Host 'Display IXE hosts' 
  $IXEHosts = $hosts | where name -match "DCB" 
  Write-host "amount of hosts $($IXEHosts.count)"

##Get possible owners for VM
  $SCVMS = Get-VM 
  $SCVMS | Select ClusterNonPossibleOwner

##Function to check the VM ownerships

## check to see if a CSV is in place
if ((Test-Path -path D:\Amar\VM-Audit)) { 

 write-host "No CSV in place performing single VM Audit on $($VMinput0) "
 $VMsinUSe = $scvms | ?{$_.name -like "*$VMinput7*" } 
 $VMsinUSe | select  name, @{n='NonPossOwners';e={$($_.ClusterNonPossibleOwner -join ", ")}},  @{n='HostType';e={$VMsinUSe.customProperty.'Host Type'}} 
} else {

  Write-host "CSV in place performing Audit on Speadsheet $VMinput0"
  $VMStoAudit = import-csv "D:\Amar\VM-Audit\$VMinput0"
  $VMsinUSe = $scvms | % { $_ 
    $currentVM = $_
    $VMStoAudit | ? { $_.name -like $currentVM.name }
    }
}

##get-nonpossowners
$nonpossowners = ($vms | ?{ $_.location -eq "ixe"} | select -Last 1).nonpossowners

    <#
  Import-Csv 
"file exsist"}


-csv
Function Get-KSVMOwners ($VMinput0){

};cls
Get-KSVMOwners UKDCBAPO001


Function Set-KSVMOwners($VMinput1){

}

Get-KSVMOwners UKDCBAPO001
#>