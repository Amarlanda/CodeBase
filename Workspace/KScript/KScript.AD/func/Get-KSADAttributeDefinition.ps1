function Get-KSADAttributeDefinition {
  # .SYNOPSIS
  #   Get an attribute definition from XML.
  # .DESCRIPTION
  #   Get-KSADAttributeDefinition loads attribute definitions from XML. The attribute definitions are used to present values for complex attributes.
  #
  #   The format of the XML file is fixed, the following format is expected by this function:
  #
  #     <?xml version='1.0'?>
  #     <Attributes>
  #       <Attribute>
  #         <Name>Attribute-Name</Name> <!-- Mandatory -->
  #         <Type>Attribute-Type-Name</Type> <!-- Mandatory -->
  #         <Aliases> <!-- Optional -->
  #           <Alias>Alias-1</Alias>
  #         </Aliases>
  #         <Flags>FALSE</Flags> <!-- Optional, valid for Enum type only -->
  #         <ValueType>System.UInt32</ValueType> <!-- Optional, valid for Enum type only -->
  #         <Values> <!-- Optional, valid for Enum type only -->
  #           <Value Name='Constant-Name-1'>0</Value>
  #           <Value Name='Constant-Name-2'>1</Value>
  #         </Values>
  #       </Attribute>
  #     </Attributes>
  #
  #   If the Type is a .NET type (such as UInt32, UInt64, String) the value converter will attempt to cast the value to that type.
  #
  #   If the Type is Enum a .NET enumeration will be created in a dynamic assembly; the value will be cast to that.
  #
  #   If the Type is List the values will be loaded into a Hash Table.
  #
  #   If the Type is anything else the value converter will attempt to find an imported attribute converter script (see Import-KPMGADAttributeConverter).
  #
  #   If an Enum type attribute contains hyphens (-), such as msRTCSIP-OptionFlags, the attribute must be defined as follows:
  #
  #     <Attribute>
  #       <Name>msRTCSIPOptionFlags</Name>
  #       <Aliases>
  #         <Alias>msRTCSIP-OptionFlags</Alias>
  #       </Aliases>
  #       <Type>Enum</Type>
  #       <Flags>TRUE</Flags>
  #       ...
  #
  #   This allows a .NET enumeration to be created, attribute lookups will be based on the real attribute name as set in the Alias.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.AD.AttributeDefinition
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     24/06/2014 - Chris Dent - Replaced XPATH function lower-case with translate. Added support for simple lists.
  #     17/06/2014 - Chris Dent - Updated help.
  #     12/06/2014 - Chris Dent - First release
  
  [CmdLetBinding(DefaultParameterSetName = 'AllAttributes')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'AttributeByName')]
    [ValidateNotNullOrEmpty()]
    [String]$AttributeName,
    
    [Parameter(ParameterSetName = 'AttributeByType')]
    [ValidateNotNullOrEmpty()]
    [String]$AttributeType,

    [ValidateScript( { $_ | ForEach-Object { Test-Path $_ } } )]
    [String]$FileName = $(Resolve-Path $psscriptroot\..\var\standard-attributes.xml | Select-Object -ExpandProperty Path)
  )

  $XPathNavigator = New-KSXPathNavigator -FileName $FileName
  
  $XPathExpression = switch ($pscmdlet.ParameterSetName) {
    'AllAttributes'   { "/Attributes/Attribute" }
    'AttributeByName' { "/Attributes/Attribute[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($AttributeName.ToLower())' or translate(Aliases/Alias, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($AttributeName.ToLower())']" }
    'AttributeByType' { "/Attributes/Attribute[translate(Type, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($AttributeType.ToLower())']" }
  }

  $XPathNavigator.Select($XPathExpression) | ForEach-Object {
    $AttributeDefinition = New-Object Object
    $_.Select("./*") | ForEach-Object {
      $Node = $_
      switch ($_.Name) {
        'Aliases' {
          $Value = $Node.Select("./*") | Select-Object -ExpandProperty TypedValue
          Add-Member "aliases" -MemberType NoteProperty -Value $Value -InputObject $AttributeDefinition
          break
        }
        'Values' {
          $Values = @{}
          $Node.Select("./*") | ForEach-Object {
            $Values.Add($_.GetAttribute("Name", $null), $_.TypedValue)
          }
          Add-Member "Values" -MemberType NoteProperty -Value $Values -InputObject $AttributeDefinition
          $Values = $null
          break
        }
        'Flags' {
          Add-Member $Node.Name -MemberType NoteProperty -Value (Get-Variable $Node.TypedValue).Value -InputObject $AttributeDefinition
          break
        }
        default {
          Add-Member $Node.Name -MemberType NoteProperty -Value $Node.TypedValue -InputObject $AttributeDefinition
        }
      }
    }
    $AttributeDefinition.PSObject.TypeNames.Add("KScript.AD.AttributeDefinition")
    
    $AttributeDefinition
  }
}
