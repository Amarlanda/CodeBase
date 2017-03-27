function Restart-KSESXHost {
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
  #   Add-KSESXHost -VMHost "host1.domain.example" -Location "SomeDataCenter\SomeCluster"
  # .NOTES
  #   Author: Amar Landa
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/01/2015 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$VMHost
    
  )
  
  process {
   
    Get-VMHostService -VMHost $vmhost | 
      where {$_.Key -eq "vpxa"} | 
      Restart-VMHostService -Confirm:$false -ErrorAction SilentlyContinue 
          
  }
}
