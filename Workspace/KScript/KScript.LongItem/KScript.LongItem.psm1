#
# Module loader for KScript.LongItem
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   30/09/2014 - Chris Dent - First release.

# Libraries
$Library = 'KScript.LongItem'

$Library | ForEach-Object{
  Import-Module "$psscriptroot\lib\$_.ps1"
}

# Private functions
$Private = 'NewKSLongItemObject'

$Private | ForEach-Object {
  Import-Module "$psscriptroot\func-priv\$_.ps1"
}

# Public functions
$Public = 'Get-KSLongItem'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}