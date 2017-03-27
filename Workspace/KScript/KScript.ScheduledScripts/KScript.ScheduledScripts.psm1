#
# Module loader for KScript.ScheduledScripts
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   21/11/2014 - Chris Dent - First release.

$Private = @()

# Private functions
if ($Private.Count -ge 1) {
  $Private | ForEach-Object {
    Import-Module "$psscriptroot\func-priv\$_.ps1"
  }
}

# Public functions
$Public = 'Export-KSHubUser',
          'Remove-KSEAuditTempDocuments'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}