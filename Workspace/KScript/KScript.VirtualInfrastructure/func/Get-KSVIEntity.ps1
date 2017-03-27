function Get-KSVIEntity {
  # .SYNOPSIS
  #   Get VI (virtual infrastructure) entities registered for use with this module.
  # .DESCRIPTION
  #   Get VI (virtual infrastructure) entities registered for use with this module.
  #
  #   A VI entity is typically a management server such as a VMWare vSphere server, or a Microsoft SCVMM server.
  # .PARAMETER Description
  #   The description of a VI entity. The list of permissible descriptions is drawn from the entries within the vi-entities file to allow tab completion. Wildcards are not supported, but multiple descriptions may be specified.
  # .PARAMETER Name
  #   The name of an entity. Wildcards are supported.
  # .PARAMETER Type
  #   The entity type is used to control availability of commands and handling of return values. The list of permissible types is drawn from the entries within the vi-entities file to allow tab completion. Wildcards are not supported, but multiple types may be specified.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.VirtualInfrastructure.VIEntity
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     23/09/2014 - Chris Dent - Modified to reflect the changes to vi-entities.csv. Added ManagementDomain.
  #     22/09/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$Name,
    
    [String]$Description,
    
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$FileName = "$psscriptroot\..\var\vi-entities.csv"
  )

  dynamicparam {
    if (-not $psboundparameters.ContainsKey('FileName')) {
      $FileName = "$psscriptroot\..\var\vi-entities.csv"
    }
  
    $DynamicParamDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary
  
    "Type", "ManagementDomain" | ForEach-Object {
      $ParamName = $_
      
      $AttributeCollection = New-Object 'Collections.ObjectModel.Collection[System.Attribute]'
      
      $ParamAttribute = New-Object Management.Automation.ParameterAttribute
      $AttributeCollection.Add($ParamAttribute)
      
      $UniqueList = Import-Csv $FileName | Select-Object -ExpandProperty $ParamName -Unique
      $ParamOptions = New-Object Management.Automation.ValidateSetAttribute -ArgumentList $UniqueList
      $AttributeCollection.Add($ParamOptions)
      
      $Param = New-Object Management.Automation.RuntimeDefinedParameter -ArgumentList @($ParamName, [String[]], $AttributeCollection)

      $DynamicParamDictionary.Add($ParamName, $Param)
    }
    
    return $DynamicParamDictionary
  }
  
  process {
    $WhereStatement = New-Object Text.StringBuilder('$_')
  
    if ($psboundparameters.ContainsKey("Name"))             { $WhereStatement.Append(' -and ($_.Name -like $Name -or $_.Name -match "^$Name\.")') | Out-Null }
    if ($psboundparameters.ContainsKey("Description"))      { $WhereStatement.Append(' -and $_.Description -like $Description') | Out-Null }
    if ($psboundparameters.ContainsKey("Type"))             { $WhereStatement.Append(' -and $_.Type -in $($psboundparameters["Type"])') | Out-Null }
    if ($psboundparameters.ContainsKey("ManagementDomain")) { $WhereStatement.Append(' -and $_.ManagementDomain -in $($psboundparameters["ManagementDomain"])') | Out-Null }
    
    $WhereScriptBlock = [ScriptBlock]::Create($WhereStatement.ToString())
  
    Import-Csv $FileName | Where-Object $WhereScriptBlock | ForEach-Object {
      $_.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.VIEntity")
      
      $_
    }
  }
}