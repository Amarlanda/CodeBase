#
# Module loader for KScript.VirtualInfrastructure
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   31/10/2014 - Chris Dent - Added Set-KSVMCustomProperty, Set-KSVMOwner and Test-KSESXCredential.
#   23/09/2014 - Chris Dent - Added Get-KSVIEntity and Export-KSVMOwner.
#   18/09/2014 - Chris Dent - Added Get-KSClusterSharedVolume.
#   04/09/2014 - Chris Dent - Added Get-KSVMDiskUsage.

# Public functions
$Public = 'Export-KSVMOwner',
          'Get-KSClusterSharedVolume',
          'Get-KSVIEntity',
          'Get-KSVM',
          'Get-KSVMDiskUsage',
          'Get-KSVMSnapshot',
          'Set-KSVMCustomProperty',
          'Set-KSVMOwner',
          'Test-KSESXCredential'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}