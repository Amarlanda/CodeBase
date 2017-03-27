#
# Module loader for KScript.AccountMaintenance
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   07/11/2014 - Chris Dent - Added Update-KSDDIMapping
#   18/09/2014 - Chris Dent - Added Start-KSADUnlockUser
#   21/08/2014 - Chris Dent - Added Import-KSADTelephoneNumber
#   05/08/2014 - Chris Dent - Added Get-KSTelephoneNumber

# Public functions
$Public = 'Get-KSTelephoneNumber',
          'Import-KSADTelephoneNumber',
          'Set-KSADTelephoneNumber',
          'Start-KSADUnlockUser',
          'Start-KSADUserMaintenance',
          'Update-KSADTelephoneNumber',
          'Update-KSDDIMapping'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}
