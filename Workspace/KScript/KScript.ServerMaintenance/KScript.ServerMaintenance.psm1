#
# Module loader for KScript.ServerMaintenance
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   13/11/2014 - Chris Dent - Added KScript.Server.CrashDump, Get-KSCrashDumpSetting and Set-KSCrashDumpSetting.
#   03/11/2014 - Chris Dent - Added Clear-KSSEPDefinitionFiles.


# Create a dynamic assembly.
New-Variable ServerModuleBuilder -Value (New-KSDynamicModuleBuilder "KScript.Server" -UseGlobalVariable $false) -Scope Script

# Static enumeration definitions
$Enum = @('KScript.Server.CrashDump')

if ($Enum.Count -ge 1) {
  $Enum | ForEach-Object {
    Import-Module "$psscriptroot\enum\$_.ps1"
  }
}

$Private = @()

# Private functions
if ($Private.Count -ge 1) {
  $Private | ForEach-Object {
    Import-Module "$psscriptroot\func-priv\$_.ps1"
  }
}

# Public functions
$Public = 'Clear-KSSEPDefinitionFiles',
          'Get-KSCrashDumpSetting',
          'Set-KSCrashDumpSetting'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}
