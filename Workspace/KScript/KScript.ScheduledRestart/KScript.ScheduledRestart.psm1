#
# Module loader for KScript.ScheduledRestart
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   08/10/2014 - Chris Dent - First release.

# Public functions
$Public = 'Add-KSScheduledRestart',
          'Get-KSScheduledRestart',
          'Remove-KSScheduledRestart',
          'Start-KSScheduledRestart',
          'Update-KSScheduledRestart'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}