function New-KSModule {
  # .SYNOPSIS
  #   Create a new module for development.
  # .DESCRIPTION
  #   New-Module performs the tasks required to create a new module.
  # .PARAMETER Name
  #   The name of the new module to create.
  # .PARAMETER Description
  #   A description of the new module.
  # .PARAMETER Standalone
  #   By default, new modules depend on KScript.Base. If the module is standalone this dependency is removed. Other dependencies may be added using Update-KSModuleManifest.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   New-KSModule "SomeModule" -Description "A test module"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/11/2014 - Chris Dent - BugFix: Sent new directory objects to null.
  #     03/11/2014 - Chris Dent - BugFix: Root module document.
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$Name,
    
    [Parameter(Mandatory = $true)]
    [String]$Description,
    
    [Switch]$Standalone
  )
  
  $ProjectPath = "$Script:WorkspacePath\KScript\$Name"
  
  if ($Name -notmatch '^KScript') {
    Write-Verbose "New-KSModule: Updating module name to include KScript"
    $Name = "KScript.$Name"
  }
  
  if (Test-Path $ProjectPath) {
    Write-Error "New-KSModule: Project already exists." -Category InvalidArgument
  } else {
    New-Item "$Script:WorkspacePath\KScript\$Name" -Type Directory | Out-Null
    New-Item "$Script:WorkspacePath\KScript\$Name\enum" -Type Directory | Out-Null
    New-Item "$Script:WorkspacePath\KScript\$Name\func" -Type Directory | Out-Null
    New-Item "$Script:WorkspacePath\KScript\$Name\func-priv" -Type Directory | Out-Null
   
    $ModuleManifest = @{
      RootModule        = $Name;
      ModuleVersion     = '0.1';
      Author            = 'Chris Dent';
      CompanyName       = 'KPMG';
      Copyright         = "(c) $((Get-Date).Year) KPMG. All rights reserved.";
      Description       = $Description;
      PowerShellVersion = '3.0';
      FunctionsToExport = '*-*';
      VariablesToExport = '*';
      AliasesToExport   = '*';
      FileList          = @("$Name.psd1");
    }    
    if (-not $Standalone) {
      $ModuleManifest.Add("RequiredModules", "KScript.Base")
    }
    New-ModuleManifest -Path "$ProjectPath\$Name.psd1" @ModuleManifest
    
    Add-KSModuleFile $Name -Root
  }
}