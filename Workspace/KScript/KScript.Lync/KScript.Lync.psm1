#
# Module loader for KScript.Lync
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   13/08/2014 - Chris Dent - Added GetKSLyncPolicySearchExpression, Get-KSLyncPolicy, Test-KSLyncUserPolicy and Update-KSLyncUserPolicy.

# Private functions
$Private = 'GetKSLyncPolicySearchExpression'

$Private | ForEach-Object {
  Import-Module "$psscriptroot\func-priv\$_.ps1"
}

# Public functions
$Public = 'Disable-KSLyncUser',
          'Enable-KSLyncUser',
          'Get-KSLyncPolicy',
          'Import-KSLyncSession',
          'Start-KSLyncUserMaintenance',
          'Test-KSLyncUserPolicy',
          'Update-KSLyncUserPolicy'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}

