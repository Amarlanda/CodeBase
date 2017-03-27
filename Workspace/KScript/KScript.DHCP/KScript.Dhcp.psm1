#
# Module loader for KScript.Dhcp
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   08/01/2015 - Chris Dent - First release.

# Libraries
[Array]$Library = 'APIWrapper'

if ($Library.Count -ge 1) {
  $Library | ForEach-Object {
    Import-Module "$psscriptroot\lib\$_.ps1"
  }
}

# Static enumerations
[Array]$Enum = @()

if ($Enum.Count -ge 1) {
  New-Variable DhcpModuleBuilder -Value (New-KSDynamicModuleBuilder KScript.Dhcp -UseGlobalVariable $false) -Scope Script
  $Enum | ForEach-Object {
    Import-Module "$psscriptroot\enum\$_.ps1"
  }
}

# Private functions
[Array]$Private = @()

if ($Private.Count -ge 1) {
  $Private | ForEach-Object {
    Import-Module "$psscriptroot\func-priv\$_.ps1"
  }
}

# Public functions
[Array]$Public = 'Get-KSDhcpClient',
                 'Get-KSDhcpScope'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}


