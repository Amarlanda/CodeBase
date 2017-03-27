function Get-KSDisk {
  # .SYNOPSIS
  #   Get disks using WMI.
  # .DESCRIPTION
  #   Get-KSDisk uses WMI to get details of all disks on a computer.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER Credential
  #   By default current user is used, alternate credentials may be specified if required.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   System.Management.ManagementObject
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/01/2015 - Chris Dent - Changed Get-WmiObject to Get-CimInstance.
  #     14/11/2014 - Chris Dent - Updated to use KScript.Wmi library.
  #     21/10/2014 - Chris Dent - Suppressed errors from Get-WmiObject.
  #     10/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$ComputerName = $env:ComputerName,
    
    [PSCredential]$Credential
  )
  
  begin {
    $CimSessionOptions = New-CimSessionOption -Protocol Dcom -Culture (Get-Culture) -UICulture (Get-Culture)
  }
  
  process {
    $CimSession = New-CimSession @psboundparameters -SessionOption $CimSessionOptions

    if ($?) {
      $CimParams = @{
        CimSession          = $CimSession
        OperationTimeoutSec = 30
      }

      Get-CimInstance -ClassName MSFT_Disk -Namespace root/Microsoft/Windows/Storage @CimParams -ErrorAction SilentlyContinue |
        Select-Object `
          BootFromDisk,
          @{n='BusType';e={ [KScript.Wmi.MSFTDisk.BusType]$_.BusType }},
          FirmwareVersion,
          FriendlyName,
          Guid,
          @{n='HealthStatus';e={ [KScript.Wmi.MSFTDisk.HealthStatus]$_.HealthStatus }},
          IsBoot,
          IsClustered,
          IsOffline,
          IsReadOnly,
          IsSystem,
          @{n='KPMGSite';e={
            switch -regex ($_.UniqueId) {
              '4C32$' { "DCA" }
              '4C30$' { "DCB" }
            }
          }},
          LargestFreeExtent,
          Location,
          LogicalSectorSize,
          Manufacturer,
          Model,
          Number,
          NumberOfPartitions,
          ObjectId,
          @{n='OfflineReason';e={ [KScript.Wmi.MSFTDisk.OfflineReason]$_.OfflineReason }},
          @{n='OperationalStatus';e={ [KScript.Wmi.MSFTDisk.OperationalStatus]$_.OperationalStatus }},
          @{n='PartitionStyle';e={ [KScript.Wmi.MSFTDisk.PartitionStyle]$_.PartitionStyle }},
          Path,
          PhysicalSectorSize,
          @{n='ProvisioningType';e={ [KScript.Wmi.MSFTDisk.ProvisioningType]$_.ProvisioningType }},
          SerialNumber,
          Signature,
          Size,
          @{n='UniqueIdFormat';e={ [KScript.Wmi.MSFTDisk.UniqueIdFormat]$_.UniqueIdFormat }},
          UniqueId
    }
  }
}
