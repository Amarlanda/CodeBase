function Update-KSModuleManifest {
  # .SYNOPSIS
  #   Update an existing module manifest file.
  # .DESCRIPTION
  #   Update-KSModuleManifest changes properties in an existing module manifest file.
  #
  #   Update-KSModuleManifest validates the Property parameter, but does not validate the value which is being set.
  # .PARAMETER Name
  #   The name of the module within the workspace.
  # .PARAMETER Property
  #   The property within the manifest to update.
  # .PARAMETER Value
  #   An arbitrary value to set. Validation of the value is left to New-ModuleManifest.
  # .INPUTS
  #   System.String
  #   System.Object
  # .EXAMPLE
  #   Update-KSModuleManifest "SomeModule" -Property ModuleVersion -Value "1.9"
  # .EXAMPLE
  #   Update-KSModuleManifest "SomeModule" -Property Guid -Value ([Guid]::NewGuid())
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name,
    
    [Parameter(Mandatory = $true)]
    [ValidateSet('AliasesToExport', 'Author', 'CLRVersion', 'CmdletsToExport', 'CompanyName', 'Copyright', 'DefaultCommandPrefix', 'Description', 'DotNetFrameworkVersion', 'FileList', 'FormatsToProcess', 'FunctionsToExport', 'GUID', 'HelpInfoURI', 'ModuleList', 'ModuleVersion', 'NestedModules', 'PowerShellHostName', 'PowerShellHostVersion', 'PowerShellVersion', 'PrivateData', 'ProcessorArchitecture', 'RequiredAssemblies', 'RequiredModules', 'RootModule', 'ScriptsToProcess', 'TypesToProcess', 'VariablesToExport')]
    [String]$Property,
    
    [Parameter(Mandatory = $true)]
    $Value
  )  
  
  if (-not $Script:WorkspacePath) {
    Write-Error "Please use Set-KSWorkspacePath to define the workspace for this session."
    break
  }
  
  $ModuleManifestFile = "$Script:WorkspacePath\KScript\$Name\$Name.psd1"
  
  if (-not (Test-Path $ModuleManifestFile)) {
    Write-Error "Update-KSModuleManifest: Manifest file does not exist"
  } else {
    $ModuleManifest = Get-KSModuleManifest $Name
    
    if ($ModuleManifest.Contains($Property)) {
      $ModuleManifest[$Property] = $Value
    } else {
      $ModuleManifest.Add($Property, $Value) 
    }
    
    New-ModuleManifest -Path $ModuleManifestFile @ModuleManifest
  }
}