function Get-KSAsset {
  # .SYNOPSIS
  #   Get stored asset information.
  # .DESCRIPTION
  #   Get-KSAsset retrieves information from the CMDB.
  # .PARAMETER Category
  #   The inventory category to update (all items within the category will be updated). The category is qualified against the list used by Get-KSInventoryAcquirer.
  # .PARAMETER CMDBPath
  #   The path to the CMDB repository.
  # .PARAMETER Filter
  #   Add a filter to the query using a hashtable in the form @{ItemToTest = 'Value'}.
  #
  #   Note that due to limitations in XPath filtering the property name represented by ItemToTest is case sensitive and must match the case of the item in the report. The value is not case-sensitive as the comparison is forced to lower-case.
  # .PARAMETER Item
  #   The inventory item to update. The item is qualified against the list used by Get-KSInventoryAcquirer.
  # .PARAMETER Name
  #   The name of the asset to update. Typically a computer name.
  # .PARAMETER SaveToExcelFile
  #   Get-KSAsset returns a wide variety of objects. The objects 
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.InventoryItem
  # .EXAMPLE
  #   Get-KSAsset SomeServer -Item ActiveDirectory
  #
  #   Get the ActiveDirectory record from the SomeServer asset.
  # .EXAMPLE
  #   Get-KSAsset SomeServer
  #
  #   Get all records from the SomeServer asset.
  # .EXAMPLE
  #   Get-KSAsset -Item SupportedCiphers
  #
  #   Get the SupportedCiphers item from all assets.
  # .EXAMPLE
  #   Get-KSAsset -Item InstalledPackages -Filter @{Name = 'VMWare*'}
  #
  #   Get the InstalledPackages item from all assets where the asset name contains VMWare.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/01/2015 - Chris Dent - Corrected ParameterSets. Added control fields.
  #     11/11/2014 - Chris Dent - Modified DeviceType to be multi-value.
  #     07/11/2014 - Chris Dent - Added DeviceType parameter.
  #     28/10/2014 - Chris Dent - Added Filter parameter.
  #     24/10/2014 - Chris Dent - Added List option.
  #     23/10/2014 - Chris Dent - Fixed case sensitivity for Item and Category. Added AssetName property to output pipeline.
  #     22/10/2014 - Chris Dent - First release.

  [CmdLetBinding(DefaultParameterSetName = "GetItems")]
  param(
    [Parameter(Position = 1, ValueFromPipeline = $true, ValuefromPipelineByPropertyName = $true)]
    [String]$Name = "*",

    [ValidateNotNullOrEmpty()]
    [String]$DeviceType,
    
    [Parameter(ParameterSetname = "GetItems")]
    [HashTable]$Filter,

    [Parameter(ParameterSetName = 'ListAssets')]
    [Switch]$List,
    
    [ValidateNotNullOrEmpty()]
    [String]$CMDBPath = (Get-KSSetting KSCMDBPath -ExpandValue)
  )
  
  dynamicparam {
    $DynamicParameters = New-Object Management.Automation.RuntimeDefinedParameterDictionary

    $DynamicParameters.Add(
      "Category",
      (New-KSDynamicParameter -ParameterName Category -ParameterType String -ParameterSetName "GetItems" -ValidateSet (Get-KSInventoryAcquirer | Select-Object -ExpandProperty Category | Sort-Object -Unique))
    )
    $DynamicParameters.Add(
      "Item",
      (New-KSDynamicParameter -ParameterName Item -ParameterType String -ParameterSetName "GetItems" -ValidateSet (Get-KSInventoryAcquirer | Select-Object -ExpandProperty Item | Sort-Object -Unique))
    )

    return $DynamicParameters
  }
  
  begin {
    $Command = Get-Command $myinvocation.InvocationName
  
    $AcquirerParams = @{}
    if ($psboundparameters.ContainsKey("Category")) {
      $ValidValues = $Command.Parameters['Category'].Attributes[1].ValidValues
      $AcquirerParams.Add("Category", ($ValidValues | Where-Object { $_ -eq $psboundparameters['Category'] }))
    }
    if ($psboundparameters.ContainsKey("Item")) {
      $ValidValues = $Command.Parameters['Item'].Attributes[1].ValidValues
      $AcquirerParams.Add("Item", ($ValidValues | Where-Object { $_ -eq $psboundparameters['Item'] }))
    }
    $Acquirer = Get-KSInventoryAcquirer @AcquirerParams | Where-Object { $_.CmdLet }
  }
  
  process {
    Get-ChildItem "$CMDBPath\$Name.xml" |
      ForEach-Object {
        $AssetName = $_.BaseName
        $XPathNavigator = New-KSXPathNavigator $_.FullName
        
        if (-not $psboundparameters.ContainsKey('DeviceType') -or ($psboundparameters.ContainsKey('DeviceType') -and $XPathNavigator.Select('/Asset/General/DeviceTypes/DeviceType').Value -contains $DeviceType)) {
          if ($List) {
            $XPathNavigator.Select("/Asset/General") | ForEach-Object {
              $Asset = $_ | ConvertFrom-KSXPathNode -ToObject | Select-Object Name, FQDNOrIP, DeviceTypes
              $Asset.DeviceTypes = $_.Select("./DeviceTypes") | ConvertFrom-KSXPathNode -ToArray
              
              $Asset
            }
          } else {
            $Acquirer |
              ForEach-Object {
                if ($psboundparameters.ContainsKey('Filter')) {
                  $FilterString = ($Filter.Keys | ForEach-Object {
                    if ($Filter[$_] -match '[*?]') {
                      "contains(translate($_, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz'), '$($Filter[$_].ToLower() -replace '\*')')"
                    } else {
                      "translate($_, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz') = '$($Filter[$_].ToLower())'"
                    }
                  }) -join ' and '
                }
              
                $ItemNode = $XPathNavigator.Select("/Asset/$($_.Category)/$($_.Item)")
                $LastUpdate = $ItemNode.GetAttribute("LastUpdate", "")
                $LastSuccessfulUpdate = $ItemNode.GetAttribute("LastSuccessfulUpdate", "")
                $LastStatus = $ItemNode.GetAttribute("LastStatus", "")
              
                if ($_.IsMultiValue) {
                  if ($psboundparameters.ContainsKey('Filter') -and $FilterString) {
                    $XPathNavigator.Select("/Asset/$($_.Category)/$($_.Item)/*[$FilterString]")
                  } else {
                    $XPathNavigator.Select("/Asset/$($_.Category)/$($_.Item)/*")
                  }
                } else {
                  if ($psboundparameters.ContainsKey('Filter') -and $FilterString) {
                    $XPathNavigator.Select("/Asset/$($_.Category)/$($_.Item)[$FilterString]")
                  } else {
                    $XPathNavigator.Select("/Asset/$($_.Category)/$($_.Item)")
                  }
                }
              } |
              ConvertFrom-KSXPathNode -ToObject -UseTypeAttribute |
              Where-Object { $_.PSObject.Properties } |
              Select-Object *,
                @{n='AssetName';e={ $AssetName }},
                @{n='LastUpdate';e={ if ($LastUpdate) { Get-Date $LastUpdate } }},
                @{n='LastSuccessfulUpdate';e={ if ($LastSuccessfulUpdate) { Get-Date $LastSuccessfulUpdate } }},
                @{n='LastStatus';e={ $LastStatus }}
          }
        }
      }
  }
}