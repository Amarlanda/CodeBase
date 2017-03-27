function Get-KSADAttributeMap {
  # .SYNOPSIS
  #   Get attributes definitions which have been loaded into the attribute map by Import-KSADAttributeDefinition.
  # .DESCRIPTION
  #   The attribute map is used to handle complex attributes which must be converted prior to presentation.
  #
  #   The attribute map contains primitive types in a hashtable to allow fast lookups.
  # .PARAMETER AttributeName
  #   The name of an attribute to lookup.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.AD.AttributeMap
  # .EXAMPLE
  #   Get-KSADAttributeMap accountExpires
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     12/06/2014 - Chris Dent - First release

  [CmdLetBinding()]
  param(
    [String]$AttributeName
  )
  
  if (-not $Script:ADAttributes) {
    Write-Warning "The attribute map has not been initialised or is empty."
    return
  }

  if ($AttributeName) {
    if ($Script:ADAttributes.Contains($AttributeName)) {
      $ReturnObject = New-Object PsObject -Property ([Ordered]@{
        AttributeName = $AttributeName
        AttributeType = $Script:ADAttributes[$AttributeName]
      })
      $ReturnObject.PSObject.TypeNames.Add("KScript.AD.AttributeMap")
      
      $ReturnObject
    }
  } else {
    $Script:ADAttributes.Keys | ForEach-Object {
      Get-KSADAttributeMap $_
    }
  }
}