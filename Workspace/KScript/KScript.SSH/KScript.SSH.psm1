#
# Module loader for KScript.SSH
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   03/10/2014 - Chris Dent - First release.

# Public functions
$Public = 'New-KSSshClient',
          'Send-KSSshCommand'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}