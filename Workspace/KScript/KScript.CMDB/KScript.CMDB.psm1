#
# Module loader for KScript.CMDB
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   14/01/2015 - Chris Dent - Added Get-KSCimInstance.
#   09/01/2015 - Chris Dent - Added Get-KSDiskPartition.
#   05/01/2015 - Chris Dent - Added Get-KSDotNetVersion.
#   14/11/2014 - Chris Dent - Pushed WMI value enumerations to KScript.Wmi library.
#   11/11/2014 - Chris Dent - Added Get-KSScheduledTask.
#   05/11/2014 - Chris Dent - Added Set-KSAsset.
#   21/10/2014 - Chris Dent - Added Get-KSInventoryAcquirer, Get-KSNetStat, Get-KSNetworkAdapte, Get-KSSupportedCipher, New-KSAsset, Rename-KSAsset, Test-KSPoodleVulnerability and Update-KSAsset.
#   10/10/2014 - Chris Dent - Added MSFT enumerations. Added Get-KSDisk, Get-KSStorageDriver and NewKSWmiParams
#   07/08/2014 - Chris Dent - Addecd KScript.CMDB.KeyboardLayout and Get-KSDefaultRegionalSetting

# Static enumerations
[Array]$Enum = @()

if ($Enum.Count -ge 1) {
  New-Variable CMDBModuleBuilder -Value (New-KSDynamicModuleBuilder "KScript.CMDB" -UseGlobalVariable $false) -Scope Script
  $Enum | ForEach-Object {
    Import-Module "$psscriptroot\enum\$_.ps1"
  }
}

# Private functions
[Array]$Private = 'NewKSWmiParams'

if ($Private.Count -ge 1) {
  $Private | ForEach-Object {
    Import-Module "$psscriptroot\func-priv\$_.ps1"
  }
}

# Public functions
[Array]$Public = 'Get-KSAsset',
                 'Get-KSCimInstance',
                 'Get-KSDefaultRegionalSetting',
                 'Get-KSDisk',
                 'Get-KSDiskPartition',
                 'Get-KSDotNetVersion',
                 'Get-KSInstalledSoftware',
                 'Get-KSInventoryAcquirer',
                 'Get-KSLastLogon',
                 'Get-KSNetStat',
                 'Get-KSNetworkAdapter',
                 'Get-KSScheduledTask',
                 'Get-KSStorageDriver',
                 'Get-KSSupportedCipher',
                 'New-KSAsset',
                 'Rename-KSAsset',
                 'Set-KSAsset',
                 'Test-KSPoodleVulnerability',
                 'Update-KSAsset'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}