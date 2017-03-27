#
# Module loader for KScript.Wmi
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   13/11/2014 - Chris Dent - First release.

# Static enumerations
[Array]$Enum = 'KScript.Wmi.MSFTDisk.BusType',
               'KScript.Wmi.MSFTDisk.HealthStatus',
               'KScript.Wmi.MSFTDisk.OfflineReason',
               'KScript.Wmi.MSFTDisk.OperationalStatus',
               'KScript.Wmi.MSFTDisk.PartitionStyle',
               'KScript.Wmi.MSFTDisk.ProvisioningType',
               'KScript.Wmi.MSFTDisk.UniqueIdFormat',
               'KScript.Wmi.Registry.Hive',
               'KScript.Wmi.Registry.KeyboardLayout',
               'KScript.Wmi.Registry.SANPolicy',
               'KScript.Wmi.Registry.ValueType',
               'KScript.Wmi.Security.AccessRight',
               'KScript.Wmi.SoftwareLicensingProduct.LicenseStatus'

if ($Enum.Count -ge 1) {
  New-Variable WmiModuleBuilder -Value (New-KSDynamicModuleBuilder KScript.Wmi -UseGlobalVariable $false) -Scope Script
  $Enum | ForEach-Object {
    Import-Module "$psscriptroot\enum\$_.ps1"
  }
}

# Private functions
[Array]$Private = @()

if ($Private.Count -ge 1) {
  $Private | ForEach-Object {
    Import-Module "$psscriptroot\func-priv\$_.ps1"
  }
}

# Public functions
[Array]$Public = 'Get-KSRegistryValue'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}


