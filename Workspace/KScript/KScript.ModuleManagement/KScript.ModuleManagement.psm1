#
# Module loader for KScript.ModuleManagement
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   14/01/2015 - Chris Dent - Added header for this file. Added Rename-KSCmdLetIdentifier.

# Public functions
$Public = 'Add-KSModuleFile',
          'Get-KSModuleManifest',
          'New-KSModule',
          'New-KSModuleDocument',
          'New-KSModuleSPPage',
          'Rename-KSCmdLetIdentifier',
          'Set-KSSignature',
          'Update-KSModuleManifest',
          'Update-KSModuleRelease'
          
$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}

# Import environment config
if (Test-Path "$psscriptroot\var\config.csv") {
  Import-Csv "$psscriptroot\var\config.csv" | ForEach-Object {
    New-Variable $_.Name -Value $_.Value -Scope Script
  }

  if (-not $Script:WorkspacePath -or -not (Test-Path $Script:WorkspacePath -PathType Container)) {
    $Message = "Workspace path is not correctly set in $psscriptroot\var\config.csv"
    Write-Error $Message -Category InvalidOperation
  }
  if (-not $Script:PublishToPath -or -not (Test-Path $Script:PublishToPath -PathType Container)) {
    Write-Warning "PublishToPath is not correctly set in $psscriptroot\var\config.csv"
  }
} else {
  Write-Warning "Development environment configuration is not set."
}
