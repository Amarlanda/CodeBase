#
# Cache functions
#

function AddKSVIObjectCacheEntry {
  [CmdLetBinding()]
  param(
    $Id,
    
    $Value
  )
  
  if (-not $Script:VIObjectCache) {
    New-Variable VIObjectCache -Scope Script -Value @{}
  }
  
  if (-not $Script:VIObjectCache.Contains($Id)) {
    $VIObjectCacheEntry = New-Object PSObject -Property ([Ordered]@{
      Id       = $Id
      Value    = $Value
    })
    $Script:VIObjectCache.Add($Id, $VIObjectCacheEntry)
  }
}

function GetKSVIObjectCacheEntry {
  [CmdLetBinding()]
  param(
    $Id
  )
  
  if ($Script:VIObjectCache) {
    if ($psboundparameters.ContainsKey("Id")) {
      $Script:VIObjectCache[$Id]
    } else {
      $Script:VIObjectCache.Values
    }
  }
}

function ClearKSVIObjectCache {
  if ($Script:VIObjectCache) {
    Remove-Variable VIObjectCache -Scope Script
  }
}

#
# Lookup modules
#

function GetKSVMWareHost {
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$Id,
    
    [Switch]$Cache,
    
    [Switch]$CachePortGroups
  )

  $VMHost = (GetKSVIObjectCacheEntry -Id $Id).Value
  # It won't seek Network configuration if the host is already cached.
  if (-not $VMHost -or $psboundparameters.ContainsKey('CachePortGroups') -and -not $VMHost.PortGroupsCached) {
  
    $ViewParams = @{"Id" = $Id; "Property" = @('Name')}
    if ($psboundparameters.ContainsKey("CachePortGroups")) {
      $ViewParams['Property'] += 'ConfigManager'
    }
    $VMHostView = Get-View @ViewParams
    
    $VMHost = New-Object PSObject -Property ([Ordered]@{
      Name             = $VMHostView.Name
      PortGroupsCached = $false
    })
    
    if ($psboundparameters.ContainsKey('CachePortGroups')) {
      $VMHost.PortGroupsCached = $true
    
      (Get-View $VMHostView.ConfigManager.NetworkSystem -Property NetworkConfig).NetworkConfig.Portgroup.Spec | ForEach-Object {
        $Key = "$Id-$($_.Name)"
        AddKSVIObjectCacheEntry -Id $Key -Value $_.VlanId
      }
    }

    # Add the base entry
    AddKSVIObjectCacheEntry -Id $Id -Value $VMHost
  }
  return $VMHost
}

function GetKSVMWareVM {
  [CmdLetBinding(DefaultParameterSetName = 'ByName')]
  param(
    [Parameter(ParameterSetName = 'ByName')]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [Parameter(ParameterSetName = 'ById')]
    [ValidateNotNullOrEmpty()]
    $Id,
    
    [ValidateSet('Network', 'Storage')]
    [String[]]$RequestProperties
  )

  $ViewParams = @{"Property" = 'Name', 'RunTime'}
  
  if ($psboundparameters.ContainsKey("Id")) {
    $ViewParams.Add("Id", $Id)
  } elseif ($psboundparameters.ContainsKey("Name")) {
    $ViewParams.Add("ViewType", "VirtualMachine")
    $ViewParams.Add("Filter", @{Name = $Name})
  } else {
    $ViewParams.Add("ViewType", "VirtualMachine")
  }
  if ($psboundparameters.ContainsKey('RequestProperties')) {
    $RequestProperties | ForEach-Object {
      $ViewParams['Property'] += $_
    }
  }
  
  Get-View @ViewParams | ForEach-Object {
    $VMHostId = $_.RunTime.Host
  
    $VMHostParams = @{"Id" = $VMHostId}
    if ($psboundparameters.ContainsKey('RequestProperties') -and $RequestProperties -contains 'Network') {
      $VMHostParams.Add("CachePortGroups", $true)
    }
  
    $VirtualMachine = New-Object PSObject -Property ([Ordered]@{
      Name     = $_.Name
      Host     = (GetKSVMWareHost @VMHostParams).Name
      Type     = "VMWare"
      State    = $_.RunTime.PowerState
      Network  = $null
      Id       = $_.MoRef
    })
    $VirtualMachine.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.Machine")
    
    if ($psboundparameters.ContainsKey('RequestProperties') -and $RequestProperties -contains 'Network') {
      $VirtualMachine.Network = $_.Network | ForEach-Object {
        $Id = $_.ToString()
       
        $VlanObject = (GetKSVIObjectCacheEntry -Id $Id).Value
        if ($VlanObject) {
          $VlanObject
        } else {
          $NetworkView = Get-View -Id $Id -Property Name, Host
          
          $VlanIdNumber = (GetKSVIObjectCacheEntry -Id "$VMHostId-$($NetworkView.Name)").Value
          
          $VlanObject = New-Object PSObject -Property ([Ordered]@{
            Name = $NetworkView.Name
            VlanId = $VlanIdNumber
          })
          $VlanObject.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.Vlan")
          
          $VlanObject | Add-Member ToString -MemberType ScriptMethod -Force -Value {
            return [String]::Format('{0} - {1}', $this.Name, $this.VlanId)
          }
          
          AddKSVIObjectCacheEntry -Id $Id -Value $VlanObject
        }
        
        $VlanObject
      }
    }
    
    if ($psboundparameters.ContainsKey('Disk')) {
    
    }
   
    $VirtualMachine
  }
}

# Connect-VIServer ukwatapp182

ClearKSVIObjectCache

GetKSVMWareVM -Id 'VirtualMachine-vm-294' -RequestProperties 'Network'
GetKSVMWareVM -Name 'UKVMWEB014'
GetKSVMWareVM -Id 'VirtualMachine-vm-1133'
GetKSVMWareVM -Id 'VirtualMachine-vm-1131' -RequestProperties 'Network'

GetKSVIObjectCacheEntry

Measure-Command { GetKSVMWareVM -Name 'UKWGDV51044' }
Measure-Command { GetKSVMWareVM -Id 'VirtualMachine-vm-294' }



