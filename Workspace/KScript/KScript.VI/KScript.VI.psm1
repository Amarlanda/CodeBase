#
# Module loader for KScript.VI
#
# Author: Amar Landa
# Team:   Core Technologies
#
# Change log:
#    20/01/2015 - Chris Dent - Added Add-KSESXHost and Add-KSESXLicense.
#    15/01/2015 - Amar Landa - First release. Added Restart-KSESXHost.

# Static enumerations
[Array]$Enum = @()

if ($Enum.Count -ge 1) {
  New-Variable VIModuleBuilder -Value (New-KSDynamicModuleBuilder KScript.VI -UseGlobalVariable $false) -Scope Script
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
[Array]$Public = 'Add-KSESXHost',
                 'Add-KSESXLicense',
                 'Restart-KSESXHost'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}


