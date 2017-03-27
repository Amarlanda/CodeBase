function Get-KSInventoryAcquirer {
  # .SYNOPSIS
  #   Get registered inventory acquirers.
  # .DESCRIPTION
  #   The inventory acquirer file determines how individual inventory items should be retrieved. The file uses the following format:
  #
  #     <Asset>
  #       <General>
  #         <Name>SomeComputer</Name>
  #         <FQDNOrIP>1.2.3.4</FQDNOrIP>
  #         <DeviceTypes>
  #           <DeviceType>MicrosoftWindows</DeviceType>
  #         </DeviceTypes>
  #       </General>
  #       <Category>
  #         <Item>
  #           <AppliesToDeviceType>MicrosoftWindows</AppliesToDeviceType>
  #           <ItemName>ItemName</ItemName>  <!-- Optional: Used if the Item is multi-value and the name is not as simple as trimming an "s" off the Item element name (parent). -->
  #           <IsMultiValue>TRUE</IsMultiValue>  <!-- Optional: If IsMultiValue is omitted the entry is assumed to be single value -->
  #           <RefreshInterval>Never</RefreshInterval>  <!-- Optional: If omitted, the DefaultRefreshInterval value will be used. Never or a string which can be cast to a TimeSpan. -->
  #           <CmdLet>Get-Something</CmdLet>  <!-- The CmdLet used to get the requested information -->
  #           <Parameters>  <!-- Optional -->
  #             <Parameter>
  #               <Name>ComputerName</Name>
  #               <Value>%Asset\General\Name%</Value>  <!-- The value may be hard-coded, or a reference to a specific node in the inventory file. -->
  #             </Parameter>
  #           </Parameters>
  #           <OutputPipeline>  <!-- Optional -->
  #             <Expression><![CDATA[ Select-Object -ExpandProperty Thing ]]></Expression>  <!-- An output pipeline may be specified for additional processing. -->
  #           </OutputPipeline>
  #           <Properties>  <!-- Optional -->
  #             <Property>
  #               <Name>SomeProperty</Name>
  #             </Property>
  #             <Property>
  #               <Name>SomeCustomProperty</Name>
  #               <Expression><![CDATA[ SomeExpression ]]></Expression>
  #             </Property>
  #           </Properties>
  #         </Item>
  #       </Category>
  #     </Asset>
  #
  # .PARAMETER Item
  #   Get a specific Item name.
  # .PARAMETER Category
  #   Get Items of a specific category.
  # .PARAMETER AppliesToDeviceType
  #   Get Items which apply to a specific device type.
  # .PARAMETER FileName
  #   The acquirer configuration file to use. By default the var\InventoryItems.xml file from the module directory is used.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.InventoryAcquirer
  # .EXAMPLE
  #   Get-KSInventoryAcquirer -Category General
  # .EXAMPLE
  #   Get-KSInventoryAcquirer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     08/12/2014 - Chris Dent - Added RefreshInterval. DefaultRefreshInterval is presented in Update-KSAsset.
  #     10/11/2014 - Chris Dent - BugFix: Expression expansion for custom properties.
  #     05/11/2014 - Chris Dent - Added DeviceType filter.
  #     29/10/2014 - Chris Dent - Help text update.
  #     22/10/2014 - Chris Dent - Cleaned up dynamic parameter creation.
  #     21/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    $FileName = "$psscriptroot\..\var\InventoryItems.xml"
  )
  
  dynamicparam {
    if (-not $psboundparameters.ContainsKey('FileName')) {
      $FileName = "$psscriptroot\..\var\InventoryItems.xml"
    }
    $XPathNavigator = New-KSXPathNavigator $FileName
    
    $DynamicParameters = New-Object Management.Automation.RuntimeDefinedParameterDictionary
      
    $DynamicParameters.Add(
      "Category",
      (New-KSDynamicParameter -ParameterName Category -ValidateSet ($XPathNavigator.Select("/Asset/*") | Select-Object -ExpandProperty Name | Sort-Object -Unique))
    )
    $DynamicParameters.Add(
      "AppliesToDeviceType",
      (New-KSDynamicParameter -ParameterName AppliesToDeviceType -ValidateSet ($XPathNavigator.Select("/Asset/*/*/AppliesToDeviceType") | ConvertFrom-KSXPathNode -ToString | Sort-Object -Unique))
    )
    $DynamicParameters.Add(
      "Item",
      (New-KSDynamicParameter -ParameterName Item -ValidateSet ($XPathNavigator.Select("/Asset/*/*") | Select-Object -ExpandProperty Name | Sort-Object -Unique))
    )
    
    return $DynamicParameters
  }
  
  begin {
    $XPathNavigator = New-KSXPathNavigator $FileName

    if ($psboundparameters.ContainsKey("Category")) {
      $Category = $psboundparameters["Category"]
    } else {
      $Category = "*"
    }
    if ($psboundparameters.ContainsKey("Item")) {
      $Item = $psboundparameters["Item"]
    } else {
      $Item = "*"
    }
    if ($psboundparameters.ContainsKey("AppliesToDeviceType")) {
      $AppliesToDeviceType = $psboundparameters["AppliesToDeviceType"]
    }

    $XPathExpression = "/Asset/$Category/$Item"
    if ($AppliesToDeviceType) {
      $XPathExpression = "$XPathExpression[AppliesToDeviceType='$AppliesToDeviceType']"
    }
    
    $XPathNavigator.Select($XPathExpression) | ForEach-Object {
      $Acquirer = $_ | ConvertFrom-KSXPathNode -ToObject
      if ($Acquirer.Parameters) {
        $Acquirer.Parameters = $_.Select("Parameters/Parameter") | ConvertFrom-KSXPathNode -ToHashTable
      }
      if ($Acquirer.Properties) {
        $Acquirer.Properties = $_.Select("Properties/Property") | ConvertFrom-KSXPathNode -ToObject | ForEach-Object {
          if ($_.Expression) {
            Invoke-Expression "@{n='$($_.Name)';e={ $($_.Expression.Trim()) }}"
          } else {
            $_.Name
          }
        }
      }
      
      Add-Member Item -MemberType NoteProperty -Value $_.Name -InputObject $Acquirer
      Add-Member Category -MemberType NoteProperty -Value ($_.SelectAncestors([Xml.XPath.XPathNodeType]::Element, $false) | Select-Object -First 1).Name -InputObject $Acquirer
      
      $Acquirer.PSObject.TypeNames.Add("KScript.CMDB.InventoryAcquirer")
      
      $Acquirer
    }
  }
}