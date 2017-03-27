#
# Module loader for KScript.NetworkTools
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   09/01/2015 - Chris Dent - First release.

# Static enumerations
[Array]$Enum = @()

if ($Enum.Count -ge 1) {
  New-Variable NetworkToolsModuleBuilder -Value (New-KSDynamicModuleBuilder KScript.NetworkTools -UseGlobalVariable $false) -Scope Script
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
[Array]$Public = 'Connect-KSSocket',
                 'Disconnect-KSSocket',
                 'New-KSBinaryReader',
                 'New-KSSocket',
                 'Receive-KSBytes',
                 'Remove-KSSocket',
                 'Send-KSBytes',
                 'Test-KSTcpPort'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}


