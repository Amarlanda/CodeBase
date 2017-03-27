function Get-KSNetworkAdapter {
  # .SYNOPSIS
  #   Get Network Adapters using WMI.
  # .DESCRIPTION
  #   Get network adapter configuration and details of bound physical adapters using WMI.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER Credential
  #   By default current user is used, alternate credentials may be specified if required.
  # .PARAMETER UUID
  #   A universally unique identifier drawn from Win32_ComputerSystemProduct.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   System.String
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     14/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$ComputerName = (hostname),
    
    [PSCredential]$Credential
  )
  
  $WmiParams = NewKSWmiParams @psboundparameters
  
  Get-WmiObject Win32_NetworkAdapterConfiguration -Filter "IPEnabled='TRUE'" @WmiParams |
    ForEach-Object {
      $NetworkAdapter = $_.GetRelated("Win32_NetworkAdapter")
      
      $_ | Select-Object `
        IPAddress,
        IPSubnet,
        DefaultIPGateway,
        MACAddress,
        DHCPEnabled,
        DHCPLeaseObtained,
        DHCPLeaseExpires,
        DHCPServer,
        DNSServerSearchOrder,
        WINSPrimaryServer,
        WINSSecondaryServer,
        @{n='InterfaceName';e={ $NetworkAdapter.Name }},
        @{n='InterfaceManufacturer';e={ $NetworkAdapter.Manufacturer }},
        @{n='InterfaceProductName';e={ $NetworkAdapter.ProductName }},
        @{n='InterfaceConnectionID';e={ $NetworkAdapter.NetConnectionID }},
        @{n='InterfaceStatus';e={ $NetworkAdapter.NetConnectionStatus }},
        @{n='PhysicalAdapter';e={ $NetworkAdapter.PhysicalAdapter }},
        @{n='InterfaceSpeed';e={ $NetworkAdapter.Speed }}
    }
}