function Get-KSModuleManifest {
  # .SYNOPSIS
  #   Get an existing module manifest file.
  # .DESCRIPTION
  #   Get the content of an existing manifest file.
  # .PARAMETER Name
  #   The name of the module within the TFS workspace.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Collections.HashTable
  # .EXAMPLE
  #   Get-KSModuleManifest KScript.AD
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name
  )
  
  if (-not $Script:WorkspacePath) {
    Write-Error "WorkspacePath not set."
    break
  }
  
  $ModuleManifestFile = "$Script:WorkspacePath\KScript\$Name\$Name.psd1"
  
  if (-not (Test-Path $ModuleManifestFile)) {
    Write-Error "Get-KSModuleManifest: Manifest file ($ModuleManifestFile) does not exist"
  } else {
    return Invoke-Expression (Get-Content $ModuleManifestFile -Raw)
  }
}