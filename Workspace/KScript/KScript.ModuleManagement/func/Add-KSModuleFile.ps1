function Add-KSModuleFile {
  # .SYNOPSIS
  #   Add a new file to an existing module.
  # .DESCRIPTION
  #   Create a file in an existing module, adding basic content, signing the file and adding the file to the FileList in the manifest.
  # .PARAMETER Name
  #   The name of the module within the workspace.
  # .PARAMETER FileName
  #   The file to add if the file is a named script.
  # .PARAMETER Type
  #   Format, Root or Script. File names are automatically generated for all but Script files.
  # .PARAMETER Force
  #   Ignore any existing files and overwrite.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Add-KSModuleFile "SomeModule" -Root
  # .EXAMPLE
  #   Add-KSModuleFile "SomeModule" -Format
  # .EXAMPLE
  #   Add-KSModuleFile "SomeModule" -FileName "SubElement"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/11/2014 - Chris Dent - BugFix: Missing + and use of carriage return. Changed to use StringBuilder.
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'Script')]
  param(
    [Parameter(Mandatory = $true, Position = 1)]
    [String]$Name,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Script')]
    [String]$FileName,
    
    [Parameter(Mandatory = $true, ParameterSetname = 'Script')]
    [ValidateSet( 'private', 'public' )]
    [String]$ScriptType = "public",
    
    [Parameter(ParameterSetName = 'Root')]
    [Switch]$Root,
    
    [Parameter(ParameterSetName = 'Format')]
    [Switch]$Format,
    
    [Switch]$Force
  )
  
  # Initial content for Root and Script files.
  $StringBuilder = New-Object Text.StringBuilder
  
  if ($Format) {
    $FileName = "$Name.Format.ps1xml"
    $NewFile = "$Script:WorkspacePath\KScript\$Name\$FileName"

    [Void]$StringBuilder.AppendLine('<?xml version="1.0" encoding="utf-8" ?>')
    [Void]$StringBuilder.AppendLine('<Configuration>')
    [Void]$StringBuilder.AppendLine('  <ViewDefinitions>')
    [Void]$StringBuilder.AppendLine('  </ViewDefinitions>')
    [Void]$StringBuilder.AppendLine('</Configuration>')
    
  } elseif ($Root) {
    $FileName = "$Name.psm1"
    $NewFile = "$Script:WorkspacePath\KScript\$Name\$FileName"
    
    [Void]$StringBuilder.AppendLine('#')
    [Void]$StringBuilder.AppendLine("# Module loader for $Name")
    [Void]$StringBuilder.AppendLine('#')
    [Void]$StringBuilder.AppendLine('# Author: ')
    [Void]$StringBuilder.AppendLine('# Team:   ')
    [Void]$StringBuilder.AppendLine('#')
    [Void]$StringBuilder.AppendLine('# Change log:')
    [Void]$StringBuilder.AppendLine('')
    
    [Void]$StringBuilder.AppendLine('# Static enumerations')
    [Void]$StringBuilder.AppendLine('[Array]$Enum = @()')
    [Void]$StringBuilder.AppendLine('')
    [Void]$StringBuilder.AppendLine('if ($Enum.Count -ge 1) {')
    [Void]$StringBuilder.AppendLine("  New-Variable $($Name -replace 'KScript\.')ModuleBuilder -Value (New-KSDynamicModuleBuilder $Name -UseGlobalVariable `$false) -Scope Script")
    [Void]$StringBuilder.AppendLine('  $Enum | ForEach-Object {')
    [Void]$StringBuilder.AppendLine('    Import-Module "$psscriptroot\enum\$_.ps1"')
    [Void]$StringBuilder.AppendLine('  }')
    [Void]$StringBuilder.AppendLine('}')
    [Void]$StringBuilder.AppendLine('')
    
    [Void]$StringBuilder.AppendLine('# Private functions')
    [Void]$StringBuilder.AppendLine('[Array]$Private = @()')
    [Void]$StringBuilder.AppendLine('')
    [Void]$StringBuilder.AppendLine('if ($Private.Count -ge 1) {')
    [Void]$StringBuilder.AppendLine('  $Private | ForEach-Object {')
    [Void]$StringBuilder.AppendLine('    Import-Module "$psscriptroot\func-priv\$_.ps1"')
    [Void]$StringBuilder.AppendLine('  }')
    [Void]$StringBuilder.AppendLine('}')
    [Void]$StringBuilder.AppendLine('')
    
    [Void]$StringBuilder.AppendLine('# Public functions')
    [Void]$StringBuilder.AppendLine('[Array]$Public = @()')
    [Void]$StringBuilder.AppendLine('')
    [Void]$StringBuilder.AppendLine('if ($Public.Count -ge 1) {')
    [Void]$StringBuilder.AppendLine('  $Public | ForEach-Object {')
    [Void]$StringBuilder.AppendLine('    Import-Module "$psscriptroot\func\$_.ps1"')
    [Void]$StringBuilder.AppendLine('  }')
    [Void]$StringBuilder.AppendLine('}')
    [Void]$StringBuilder.AppendLine('')
  } else {
    if (-not $FileName.EndsWith(".ps1")) {
      $FileName = "$FileName.ps1"
    }
    $FileName = switch ($ScriptType) {
      'private' { "func-priv\$FileName" }
      'public'  { "func\$FileName" }
    }
    
    $NewFile = "$Script:WorkspacePath\KScript\$Name\$FileName"
  }
  
  if ((Test-Path $NewFile) -and -not $Force) {
    Write-Error "Add-KSModuleFile: File ($NewFile) already exists." -Category InvalidArgument
  } else {
    $StringBuilder.ToString() | Out-File $NewFile -Encoding ASCII

    # FormatsToProcess
    if ($Format) {
      Update-KSModuleManifest $Name -Property FormatsToProcess -Value $FileName
    }
    
    # FileList
    $ModuleManifest = Get-KSModuleManifest $Name
    $FileList = @()
    if ($ModuleManifest.Contains("FileList")) {
      $FileList += $ModuleManifest["FileList"]
    }
    if ($FileList -notcontains $FileName) {
      $FileList += $FileName
    }
    Update-KSModuleManifest $Name -Property FileList -Value $FileList
  }
}
