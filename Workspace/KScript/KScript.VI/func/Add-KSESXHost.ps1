function Add-KSESXHost {
  # .SYNOPSIS
  #   Add an ESX host to a connected vCenter server.
  # .DESCRIPTION
  #   Add-KSESXHost allows a VMHost to be added to a specific datacenter and, optionally, a cluster.
  # .PARAMETER Credential
  #   Credentials used to connect to the new ESX host.
  # .PARAMETER Location
  #   The datacenter or datacenter and cluster in which to place the new VMHost. Location should be submitted in the form DataCenter\Cluster.
  # .PARAMETER VMHost
  #   The FQDN of the host to add.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .EXAMPLE
  #
  #  Singular
  #  Add-KSESXHost -VMHost "host1.domain.example" -Location "SomeDataCenter\SomeCluster"
  #
  #  Pulral
  #  $Credential = Get-Credential
  #  Get-Content .\vm.txt | Add-KSESXHost -Location "ixe\Prod VDI Cluster01" -Credential $Credential
  #
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/01/2015 - Chris Dent - First release.


  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$VMHost,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidatePattern('^[^\\/]+(?:[\\/][^\\/]+)?$')]
    [String]$Location,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [PSCredential]$Credential
  )

  
  process {
    $DataCenter = Get-Datacenter (Split-Path $Location)
    if ($Location -match '[\\/]([^\\/]+)$') {
      $LocationObject = $DataCenter | Get-Cluster $matches[1]
    } else {
      $LocationObject = $DataCenter
    }
   
    Add-VMHost $VMHost -Location $LocationObject -User $Credential.Username -Password $Credential.GetNetworkCredential().Password -force -confirm:$false

  }
}

 #$Credential = Get-Credential
 #Get-Content .\vm.txt | Add-KSESXHost -Location "ixe\Prod VDI Cluster01" -Credential $Credential