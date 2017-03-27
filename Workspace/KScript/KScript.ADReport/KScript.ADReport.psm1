#
# Module loader for KPMG.ADReport
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   12/08/2014 - Chris Dent - Added Start-KSADReport

# Public functions
$Public = 'Get-KSADReport',
          'Publish-KSADReport',
          'Start-KSADReport'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}