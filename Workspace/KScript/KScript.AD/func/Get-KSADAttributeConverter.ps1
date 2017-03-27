function Get-KSADAttributeConverter {
  # .SYNOPSIS
  #   Get imported AD attribute converters.
  # .DESCRIPTION
  #   Get-KSADAttributeConverter displays all loaded attribute converters.
  # .PARAMETER AttributeType
  #   The converter to lookup by attribute type.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.AD.AttributeConverter
  # .EXAMPLE
  #   Get-KSADAttributeConverter LargeIntegerDate
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/06/2014 - Chris Dent - First release  
 
  [CmdLetBinding()]
  param(
    [String]$AttributeType
  )

  if (-not $Script:ADAttributeConverters) {
    Write-Warning "No attribute converters have been loaded."
    return
  }

  if ($AttributeType) {
    if ($Script:ADAttributeConverters.Contains($AttributeType)) {
      if (Test-Path "function:\$AttributeType") {
        $Definition = Get-Item "function:\$AttributeType" | Select-Object -ExpandProperty Definition
      }
    
      $ReturnObject = New-Object PsObject -Property ([Ordered]@{
        AttributeType = $AttributeType
        SourcePath    = $Script:ADAttributeConverters[$AttributeType]
        Definition    = $Definition
      })
      $ReturnObject.PSObject.TypeNames.Add("KPMG.AD.AttributeConverter")
      
      $ReturnObject
    }
  } else {
    $Script:ADAttributeConverters.Keys | ForEach-Object {
      Get-KSADAttributeConverter $_
    }
  }
}