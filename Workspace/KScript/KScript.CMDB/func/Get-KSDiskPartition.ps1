function Get-KSDiskPartition {
  # .SYNOPSIS
  #   Get disk partitions using WMI.
  # .DESCRIPTION
  #   Get-KSDiskPartition uses WMI to get details of all disk partitions on a computer.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER Credential
  #   By default current user is used, alternate credentials may be specified if required.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.DiskPartition
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/01/2015 - Chris Dent - Simplified instantiation of CimSession.
  #     09/01/2015 - Chris Dent - First release.

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
      
      Get-CimInstance -ClassName Win32_DiskPartition @CimParams | ForEach-Object {
        $DiskDrive = $_ | Get-CimAssociatedInstance -ResultClassName Win32_DiskDrive @CimParams
        $LogicalDisk = $_ | Get-CimAssociatedInstance -ResultClassName Win32_LogicalDisk @CimParams
        $Volume = Get-CimInstance -ClassName Win32_Volume -Filter "Name='$($LogicalDisk.DeviceID)\\'" @CimParams
      
        $ReturnObject = $_ | Select-Object `
          Name,
          @{n='BlockSize';e={ $Volume.BlockSize }},
          Bootable,
          DeviceID,
          PrimaryPartition,
          Size,
          StartingOffset,
          @{n='DiskDriveDeviceID';e={ $DiskDrive.DeviceID }},
          @{n='LogicalDiskDeviceID';e={ $LogicalDisk.DeviceID }},
          @{n='FileSystem';e={ $LogicalDisk.FileSystem }},
          @{n='LogicalDiskFreeSpace';e={ $LogicalDisk.FreeSpace }},
          @{n='LogicalDiskSize';e={ $LogicalDisk.Size }},
          @{n='LogicalDiskVolumeName';e={ $LogicalDisk.VolumeName }}
          
        $ReturnObject.PSObject.TypeNames.Add("KScript.CMDB.DiskPartition")
        
        $ReturnObject
      }
    }
  }
}