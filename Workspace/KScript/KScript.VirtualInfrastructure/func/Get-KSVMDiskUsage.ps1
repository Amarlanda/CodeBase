function Get-KSVMDiskUsage {
  # .SYNOPSIS
  #   Get the disk space used by a virtual machine managed by a vCenter server.
  # .DESCRIPTION
  #   Get the disk space used by a virtual machine managed by a vCenter server (including space used by snapshot images).
  # .PARAMETER VIEntity
  #   VIEntity is used to target the script at a specific environment. The list of available environments can be seen by running Get-KSVIEntity. If no value is set the current management domain (based on UserDnsDomain) is used.
  # .PARAMETER VMName
  #   The name of a virtual machine.
  # .INPUTS
  #   KScript.VirtualInfrastructure.VIEntity
  #   System.String
  # .OUTPUTS
  #   KScript.VirtualInfrastructure.VMDiskUsage
  # .EXAMPLE
  #   Get-KSVMDiskUsage
  # .EXAMPLE
  #   Get-KSVMDiskUsage -VMName VMName
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     04/09/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$VMName,
    
    [Parameter(ValueFromPipeline = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.VirtualInfrastructure.VIEntity' } )]
    $VIEntity
  )
  
  begin {
    if (-not (Get-PSSnapIn VMWare.VimAutomation.Core -ErrorAction SilentlyContinue)) {
      Write-Error "Get-KSVMDiskUsage must be able to use the snap-in VMWare.VimAutomation.Core (vSphere tools)."
      break
    }
  }
  
  process {
    if (-not $psboundparameters.ContainsKey('VIEntity')) {
      # Default to the current management domain.
      Get-KSVIEntity -ManagementDomain $env:UserDnsDomain | Get-KSVMDiskUsage @psboundparameters
      break
    }  
  
    if ($VMName) {
      $Params = @{}
      if ($psboundparameters.ContainsKey("VMName")) {
        $Params.Add("Name", $VMName)
      }
    }
  
    if ($VIEntity.Type -eq 'vCenter') {
      Write-Progress "Searching $($VIEntity.Name)" -Activity $VMName

      Connect-VIServer $VIEntity.Name -Force -WarningAction SilentlyContinue | Out-Null

      VMWare.VimAutomation.Core\Get-VM @Params | ForEach-Object {
        $HardDisks = $_ | Get-HardDisk
      
        $VM = $_ | Select-Object `
          Name,
          Notes,
          PowerState,
          MemoryGB,
          @{n='HardDiskCount';e={ $HardDisks | Measure-Object | Select-Object -ExpandProperty Count }},
          Host,
          UsedSpaceGB,
          ProvisionedSpaceGB,
          @{n='SnapshotSpaceUsed';e={ ($_ | Get-Snapshot | Measure-Object SizeGb -Sum).Sum }},
          @{n='VIEntityName';e={ $VIEntity.Name }}
        
        if ($VM.ProvisionedSpaceGB -eq -1) {
          $VM.ProvisionedSpaceGB = ($HardDisks | Measure-Object CapacityGB -Sum).Sum
        }
        if ($VM.UsedSpaceGB -eq -1) {
          $VM.UsedSpaceGB = ($HardDisks | ForEach-Object {
            if ($_.Filename -match '\[(?<Datastore>[^\]]+)\] (?<File>.+)$') {
              Get-Datastore $matches.Datastore | ForEach-Object {
                $VMDKPath = "$($_.DatastoreBrowserPath)\$($matches.File)"
                if (Test-Path $VMDKPath) {
                  (Get-Item $VMDKPath).Length / 1Gb
                }
              }
            }
          } | Measure-Object -Sum).Sum
        }

        $VM | Add-Member EstimatedSpaceRequired -MemberType ScriptProperty -Value {
          $this.UsedSpaceGB + $this.MemoryGB
        }
  
        $VM.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.VMDiskUsage")
  
        $VM
      }
      
      Disconnect-VIServer -Confirm:$false
    }
  }
}