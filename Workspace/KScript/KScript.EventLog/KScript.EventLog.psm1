#
# Module loader for KScript.EventLog
#

# Public functions
$Public = 'Get-KSAccountLockoutLog',
          'Get-KSUnexpectedRebootEvent',
          'Invoke-KSGetWinEvent'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}