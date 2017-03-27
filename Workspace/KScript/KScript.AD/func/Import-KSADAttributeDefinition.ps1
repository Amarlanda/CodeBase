function Import-KSADAttributeDefinition {
  # .SYNOPSIS
  #   Import attribute definitions onto the current session.
  # .DESCRIPTION
  #   Attribute definitions are read from XML using Get-KSADAttributeDefintion. Each attribute definition may be imported into the current session using Import-KSADAttributeDefinition.
  #
  #   Imported attribute definitions are used to present friendly views of specific Active Directory attributes.
  #
  #   The split between Get and Import allows attribute definitions to be imported from different sources.
  # .PARAMETER AttributeDefinition
  #   The definition of an attribute from Get-KSADAttributeDefinition.
  # .PARAMETER Force
  #   Overwrite the existing attribute definition. Note: Enum values cannot be overwritten.
  # .INPUTS
  #   KPMG.AD.AttributeDefinition
  # .EXAMPLE
  #   Get-KSADAttributeDefinition | Import-KSADAttributeDefinition
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     24/06/2014 - Chris Dent - Added support for simple lists. 
  #     13/06/2014 - Chris Dent - Added Force parameter. Implemented duplicate checking.
  #     12/06/2014 - Chris Dent - First release  

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.AD.AttributeDefinition' } )]
    $AttributeDefinition,
    
    [Switch]$Force
  )

  begin {
    if (-not $Script:ADAttributes) {
      New-Variable ADAttributes -Value @{} -Scope Script
    }
    
    $NewEnumParams = @{ModuleBuilder = ($Script:ADModuleBuilder); Flags = $false}
  }
  
  process {
  
    if ($Script:ADAttributes.Contains($AttributeDefinition.Name)) {
      if ($AttributeDefinition.Type -eq 'Enum' -and $Force) {
        Write-Error "Cannot overwrite Enumeration definition. Type must be changed or conflict manually resolved."
        return
      } elseif (-not $Force) {
        Write-Error "Duplicate attribute definition. Ignoring $($AttributeDefinition.Name)."
        return
      }
    }
  
    switch ($AttributeDefinition.Type) {
      'Enum' {
        if ($AttributeDefinition.Flags) { $NewEnumParams["Flags"] = $true } else { $NewEnumParams["Flags"] = $false }
        New-KSEnum -Name "KScript.AD.$($AttributeDefinition.Name)" -Type $AttributeDefinition.ValueType -Members $AttributeDefinition.Values @NewEnumParams

        # Add details of this mapping to the ADAttribute hashtable.
        $Script:ADAttributes.Add($AttributeDefinition.Name, "KScript.AD.$($AttributeDefinition.Name)")
        # Add details of aliased mappings to the ADAttribute hashtable.
        if ($AttributeDefinition.Aliases) {
          $AttributeDefinition.Aliases | ForEach-Object {
            $Script:ADAttributes.Add($_, "KScript.AD.$($AttributeDefinition.Name)")
          }
        }
        break
      }
      'List' {
        # Reverse the key / value assignment in the hashtable.
        $Values = @{}
        $AttributeDefinition.Values.Keys | ForEach-Object {
          $Values.Add($AttributeDefinition.Values[$_], $_)
        }
        $Script:ADAttributes.Add($AttributeDefinition.Name, $Values)
      }
      default {
        $Script:ADAttributes.Add($AttributeDefinition.Name, $AttributeDefinition.Type)
      }
    }
  }
}