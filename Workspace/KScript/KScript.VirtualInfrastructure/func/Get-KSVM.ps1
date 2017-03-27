function Get-KSVM {
  # .SYNOPSIS
  #   Search for a virtual machine across all known platforms.
  # .DESCRIPTION
  #   Get-KSVM attempts to find a virtual machine by name across all platforms.
  # .PARAMETER VIEntity
  #   VIEntity is used to target the script at a specific environment. The list of available environments can be seen by running Get-KSVIEntity. If no value is set the current management domain (based on UserDnsDomain) is used.
  # .PARAMETER VMName
  #   The name of the VM to search for. Wildcards are supported.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.VirtualInfrastructure.Machine
  # .EXAMPLE
  #   Get-KSVM ukwatapp056
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     17/11/2014 - Chris Dent - Modified to include search of VDI estate.
  #     30/09/2014 - Chris Dent - Modified wildcard handling.
  #     02/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$VMName,
    
    [Parameter(ValueFromPipeline = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.VirtualInfrastructure.VIEntity' } )]
    $VIEntity
  )
  
  begin {
    $EnableVMWareQuery = $EnableSCVMMQuery = $true
  
    if (-not (Get-PSSnapIn VMWare.VimAutomation.Core -ErrorAction SilentlyContinue)) {
      Write-Warning "Get-KSVM must be able to use the snap-in VMWare.VimAutomation.Core (vSphere tools) to query VMWare vSphere."
      $EnableVMWareQuery = $false
    }
  
    if (-not (Get-Module virtualmachinemanager)) {
      Write-Warning "Get-KSClusterSharedVolume must be able to use the module virtualmachinemanager (SCVMM) to query SCVMM."
      $EnableSCVMMQuery = $false
    }
  
    if ($EnableVMWareQuery -eq $false -and $EnableSCVMMQuery -eq $false) {
      Write-Error "No VI types to query. Aborting."
      break
    }
    
    $VIHosts = @{}
    $PortGroups = @{}
  }
  
  process {
    if (-not $psboundparameters.ContainsKey('VIEntity')) {
      # Default to the current management domain.
      Get-KSVIEntity -ManagementDomain $env:UserDnsDomain | Get-KSVM @psboundparameters
      break
    }

    if ($VIEntity.Type -in 'vCenter', 'vCenter-VDI') {
      if ($EnableVMWareQuery) {
        Write-Progress "Searching $($VIEntity.Name)"
        
        Connect-VIServer $VIEntity.Name -Force -WarningAction SilentlyContinue | Out-Null

        $Params = @{}
        if ($psboundparameters.ContainsKey('VMName')) {
          $Params.Add('Filter', @{Name = $VMName})
        }
        Get-View -ViewType VirtualMachine @Params | ForEach-Object {
          if ($VIHosts.Contains($_.RunTime.Host)) {
            $VMHost = $VIHost[$_.RunTime.Host]
          } else {
            $VMHost = Get-View -ID $_.RunTime.Host
            
            (Get-View $VMHost.ConfigManager.NetworkSystem).NetworkConfig.Portgroup.Spec | ForEach-Object {
              $Key = "$($VMHost.Name)-$($_.Name)"
              if (-not $PortGroups.Contains($Key)) {
                $PortGroups.Add($Key, $_.VlanID)
              }
            }
          }
        
          $VlanID = $_.Network | ForEach-Object { Get-View $_ } | Where-Object { $_.Name -ne 'backup' } | ForEach-Object {
            $PortGroups["$($VMHost.Name)-$($_.Name)"]
          }
      
          $Machine = New-Object PSObject -Property ([Ordered]@{
            Name         = $_.Name
            Notes        = $_.Config.Annotation
            PowerState   = $_.RunTime.PowerState
            VMHost       = $VMHost.Name
            VlanID       = $VlanID
            Type         = $VIEntity.Type
            SearchName   = $VMName
            VIEntityName = $VIEntity.Name
          })
          
          $Machine.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.Machine")
          
          $Machine
        }
        
        Disconnect-VIServer -Confirm:$false
      }
    } elseif ($VIEntity.Type -eq 'SCVMM') {
      if ($EnableSCVMMQuery) {
        if (Get-VMMServer $VIEntity.Name) {
          Get-SCVMHostCluster | ForEach-Object {
            Write-Progress "Searching $($VIEntity.Name)"

            $Params = @{}
            if ($psboundparameters.ContainsKey('VMName') -and $VMName -notmatch '\*') {
              $Params.Add("Name", $VMName)
              $LikeVMName = '*'
            } elseif ($psboundparameters.ContainsKey('VMName') -and $VMName -match '\*') {
              $LikeVMName = $VMName
            } else {
              $LikeVMName = '*'
            }
            
            $_ |
              Get-SCVMHost |
              Get-SCVirtualMachine @Params |
              Where-Object Name -like $LikeVMName |
              ForEach-Object {
                $Machine = New-Object PSObject -Property ([Ordered]@{
                  Name         = $_.Name
                  Notes        = $_.Notes
                  PowerState   = $_.VirtualMachineState
                  VMHost       = $_.HostName
                  VlanID       = $null
                  Type         = $VIEntity.Type
                  SearchName   = $VMName
                  VIEntityName = $VIEntity.Name
                })
                
                $Machine.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.Machine")
          
                $Machine
              }

          }
        }
      }
    }
  }
}