#
# Module loader for KScript.Crypto
#
# Author: 
# Team:   
#
# Change log:

# Static enumerations
[Array]$Enum = @()

if ($Enum.Count -ge 1) {
  New-Variable CryptoModuleBuilder -Value (New-KSDynamicModuleBuilder KScript.Crypto -UseGlobalVariable $false) -Scope Script
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
[Array]$Public = @()

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}


