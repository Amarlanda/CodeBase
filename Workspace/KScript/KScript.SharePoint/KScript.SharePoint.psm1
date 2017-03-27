# Variables consumed by this module
New-Variable KPMG_SPSite -Scope Script

# Private functions
Import-Module $psscriptroot\func-priv\GetKPMGSPInterface.ps1

# Public functions
Import-Module $psscriptroot\func\Get-KPMGSPSite.ps1
Import-Module $psscriptroot\func\Get-KPMGSPList.ps1
Import-Module $psscriptroot\func\Get-KPMGSPItem.ps1