#
# Module loader for KScript.Base
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   10/12/2014 - Chris Dent - Added Set-KSXPathAttribute.
#   22/10/2014 - Chris Dent - Added ConvertTo-KSType and New-KSDynamicParameter.
#   21/10/2014 - Chris Dent - Added ConvertTo-KSXml.
#   06/10/2014 - Chris Dent - Added Compare-KSArray.
#   07/08/2014 - Chris Dent - Added Start-KSLogRotate.

# Private functions
$Private = 'NewKSLog'

$Private | ForEach-Object {
  Import-Module "$psscriptroot\func-priv\$_.ps1"
}

# Public functions
$Public = 'Close-KSLog',
          'Compare-KSArray',
          'ConvertFrom-KSTokenString',
          'ConvertFrom-KSXPathNode',
          'ConvertTo-KSByte',
          'ConvertTo-KSString',
          'ConvertTo-KSTimeSpanString',
          'ConvertTo-KSTokenString',
          'ConvertTo-KSType',
          'ConvertTo-KSXml',
          'Get-KSCommandParameters',
          'Get-KSEventLogCode',
          'Get-KSHash',
          'Get-KSLog',
          'Get-KSModule',
          'Get-KSSetting',
          'Get-KSSMTPConfiguration',
          'Get-KSTextResource',
          'Install-KSModule',
          'New-KSDynamicModuleBuilder',
          'New-KSDynamicParameter',
          'New-KSEnum',
          'New-KSXPathNavigator',
          'Remove-KSEventLogCode',
          'Remove-KSSetting',
          'Set-KSEventLogCode',
          'Set-KSSetting',
          'Set-KSXPathAttribute',
          'Start-KSAutoUpdate',
          'Start-KSLogRotate',
          'Update-KSPropertyOrder',
          'Write-KSLog'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}

Get-KSSetting -GlobalVariable | Where-Object { $_ } | ForEach-Object {
  New-Variable $_.Name -Value $_.Value -Scope Global -Force
}
if (Get-KSSetting KSModuleAutoUpdate -ExpandValue) {
  Start-KSAutoUpdate
}