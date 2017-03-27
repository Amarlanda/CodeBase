#
# Module loader for KScript.AD
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   21/11/2014 - Chris Dent - Added Get-KSADDhcpServer.
#   04/11/2014 - Chris Dent - Added Get-KSADClass.
#   25/09/2014 - Chris Dent - Added Get-KSLocalGroup and Get-KSLocalGroupMember.
#   22/09/2014 - Chris Dent - Added Get-KSADFSMORoleOwner.
#   02/09/2014 - Chris Dent - Added Get-KSADDomain.
#   07/08/2014 - Chris Dent - BugFix: Missing ,.
#   06/08/2014 - Chris Dent - Added ConvertFrom-KSSID
#   05/08/2014 - Chris Dent - Added Get-KSADGroupMember.
#   04/08/2014 - Chris Dent - Moved module builder declaration.
#   18/07/2014 - Chris Dent - Added change logging here. Added Get-KSADGroup.

# Create a dynamic assembly.
New-Variable ADModuleBuilder -Value (New-KSDynamicModuleBuilder "KScript.AD" -UseGlobalVariable $false) -Scope Script

# Static enumeration definitions
$Enum = 'KScript.AD.IADSControlCode',
        'KScript.NameTranslate.InitType',
        'KScript.NameTranslate.NameType'

$Enum | ForEach-Object {
  Import-Module "$psscriptroot\enum\$_.ps1"
}

# Private functions
$Private = 'ConvertFromKSADIdentity',
           'ConvertFromKSADLargeInteger',
           'ConvertFromKSADPropertyCollection',
           'ConvertFromKSADWrappedInteger',
           'NewKSADDirectoryEntry'

$Private | ForEach-Object {
  Import-Module "$psscriptroot\func-priv\$_.ps1"
}

# Public functions
$Public = 'Add-KSADUserPhoto',
          'Convert-KSADName',
          'ConvertFrom-KSSID',
          'Disable-KSADComputer',
          'Disable-KSADUser',
          'Enable-KSADComputer',
          'Enable-KSADUser',
          'Expand-KSADLdapFilter',
          'Get-KSADAttribute',
          'Get-KSADAttributeConverter',
          'Get-KSADAttributeDefinition',
          'Get-KSADAttributeMap',
          'Get-KSADClass',
          'Get-KSADComputer',
          'Get-KSADDhcpServer',
          'Get-KSADDomain',
          'Get-KSADDomainController',
          'Get-KSADDomainPasswordPolicy',
          'Get-KSADExchangeServer',
          'Get-KSADFSMORoleOwner',
          'Get-KSADGroup',
          'Get-KSADGroupMember',
          'Get-KSADLastLogon',
          'Get-KSADMemberOf',
          'Get-KSADObject',
          'Get-KSADOrganizationalUnit',
          'Get-KSADRootDSE',
          'Get-KSADSite',
          'Get-KSADUser',
          'Get-KSLocalGroup',
          'Get-KSLocalGroupMember',
          'Get-KSLocalUser',
          'Import-KSADAttributeConverter',
          'Import-KSADAttributeDefinition',
          'Remove-KSADUserPhoto',
          'Set-KSADUser',
          'Show-KSADUserPhoto',
          'Unlock-KSADUser'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}

# Import the standard attribute map
Get-KSADAttributeDefinition | Import-KSADAttributeDefinition
# Import KPMG specific attribute map
Get-KSADAttributeDefinition -FileName "$psscriptroot\var\kpmg-attributes.xml" | Import-KSADAttributeDefinition

# Import attribute converters
$Converters = 'GUIDObject',
              'LargeIntegerDate',
              'LargeIntegerTimespan',
              'SecondTimespan',
              'SIDObject'

$Converters | ForEach-Object {
  Import-KSADAttributeConverter "$psscriptroot\var\type-converters\$_.ps1" -ImportAsFunction
}