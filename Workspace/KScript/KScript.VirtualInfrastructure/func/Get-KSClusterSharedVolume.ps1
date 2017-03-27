function Get-KSClusterSharedVolume {
  # .SYNOPSIS
  #   Get cluster shared volumes.
  # .DESCRIPTION
  #   Get cluster shared volumes along with the World-Wide-Name (WWN) for the volume.
  #
  #   Get-KSClusterSharedVolume requires access to SCVMM using the virtualmachinemanager module as well as any Host Clusters. The Host Clusters are accessed using the failoverclusters module.
  # .PARAMETER VIEntity
  #   VIEntity is used to target the script at a specific environment. The list of available environments can be seen by running Get-KSVIEntity. If no value is set the current management domain (based on UserDnsDomain) is used.
  # .OUTPUTS
  #   KScript.VirtualInfrastructure.ClusterSharedVolume
  # .EXAMPLE
  #   Get-KSClusterSharedVolume
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     23/09/2014 - Chris Dent - Modified to use and accept a pipeline from Get-KSVIEntity.
  #     18/09/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.VirtualInfrastructure.VIEntity' } )]
    $VIEntity
  )
  
  begin {
    if (-not ((Get-Module virtualmachinemanager) -and (Get-Module failoverclusters))) {
      Write-Error "Get-KSClusterSharedVolume must be able to use the modules virtualmachinemanager (SCVMM) and failoverclusters."
      break
    }
  }
  
  process {
    if (-not $psboundparameters.ContainsKey('VIEntity')) {
      # Default to the current management domain.
      Get-KSVIEntity -ManagementDomain $env:UserDnsDomain | Get-KSClusterSharedVolume @psboundparameters
      break
    }
  
    if ($VIEntity.Type -eq 'SCVMM') {
      if (Get-VMMServer $VIEntity.Name) {
        Get-SCVMHostCluster | ForEach-Object {
          $Cluster = $_.Name
          
          # Capture the disks associated with the cluster
          Get-ClusterSharedVolume -Cluster $_.Name |
            Select-Object Name, OwnerNode, State,
              @{n='CSVPath';e={ $_.SharedVolumeInfo.FriendlyVolumeName }},
              @{n='CSVWWN';e={
                # Acquire the WWN for the disk.
                $StorageVolumeId = $_.SharedVolumeInfo.Partition.Name -replace '\\\\\?\\Volume\{|\}\\'
                
                Get-SCVMHost $_.OwnerNode | Select-Object -ExpandProperty Disks |
                  Where-Object { $_.DiskVolumes.StorageVolumeId -match $StorageVolumeId } |
                  Select-Object -ExpandProperty SmLUNId
              }},
              @{n='SCVMCluster';e={ $Cluster }},
              @{n='Site';e={ $_.OwnerNode -match '^\w{2}(?<Site>\w{3})' | Out-Null; $matches.Site }},
              @{n='VIEntityName';e={ $VIEntity.Name }} |
            ForEach-Object {
              $_.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.ClusterSharedVolume")
              
              $_
            }
        }
      }
    }
  }
}