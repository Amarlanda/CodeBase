function Update-KSAsset {
  # .SYNOPSIS
  #   Update an asset record.
  # .DESCRIPTION
  #   Update an asset record using the commands defined by Get-KSInventoryAcquirer.
  #
  #   The DNS inventory item included with this module requires the DNS resolver from Indented.Dns.
  # .PARAMETER Category
  #   The inventory category to update (all items within the category will be updated). The category is qualified against the list used by Get-KSInventoryAcquirer.
  # .PARAMETER CMDBPath
  #   The path to the CMDB repository.
  # .PARAMETER DefaultRefreshInterval
  #   The interval during which asset record update requests will be ignored unless Force is set. By default the interval is 7 days.
  # .PARAMETER Force
  #   Force a file update regardless of the NoRefreshInterval.
  # .PARAMETER Item
  #   The inventory item to update. The item is qualified against the list used by Get-KSInventoryAcquirer.
  # .PARAMETER Name
  #   The name of the asset to update. Typically a computer name.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Update-KSAsset SomeComputer
  # .EXAMPLE
  #   Update-KSAsset SomeComputer -Force
  #
  #   Forcefully update all items associated with the asset SomeComputer.
  # .EXAMPLE
  #   Update-KSAsset SomeComputer -Item BoundPorts -Force
  #
  #   Forcefully update the BoundPorts item for the asset SomeComputer.
  # .LINK
  #   http://www.indented.co.uk/indented-dns/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     10/12/2014 - Chris Dent - Updated to use Set-KSXPathAttribute.
  #     08/12/2014 - Chris Dent - No longer deletes stored information. Renamed NoRefreshInterval to DefaultRefreshInterval and changed value to 3 days.
  #     20/11/2014 - Chris Dent - Updated passed parameters to support nodes containing objects.
  #     11/11/2014 - Chris Dent - Added check for existence of CmdLet prior to execution. Added support for multiple DeviceTypes.
  #     05/11/2014 - Chris Dent - Added DeviceType filtering for InventoryItems.
  #     31/10/2014 - Chris Dent - BugFix: PassedParameters will only add is Value is not null.
  #     29/10/2014 - Chris Dent - Added ability to remove items which do not successfully return.
  #     27/10/2014 - Chris Dent - BugFix: ScriptBlock parameter passing.
  #     23/10/2014 - Chris Dent - Dropped empty responses; Better support for incremental updates.
  #     22/10/2014 - Chris Dent - Cleaned up dynamic parameters.
  #     21/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, ValuefromPipelineByPropertyName = $true)]
    [String]$Name = "*",
    
    [TimeSpan]$DefaultRefreshInterval = (New-TimeSpan -Days 7),
    
    [Switch]$Force,
    
    [ValidateNotNullOrEmpty()]
    [String]$CMDBPath = (Get-KSSetting KSCMDBPath -ExpandValue)
  )
  
  dynamicparam {
    $DynamicParameters = New-Object Management.Automation.RuntimeDefinedParameterDictionary

    $DynamicParameters.Add(
      "Category",
      (New-KSDynamicParameter -ParameterName Category -ParameterType String -ValidateSet (Get-KSInventoryAcquirer | Select-Object -ExpandProperty Category | Sort-Object -Unique))
    )
    $DynamicParameters.Add(
      "Item",
      (New-KSDynamicParameter -ParameterName Item -ParameterType String -ValidateSet (Get-KSInventoryAcquirer | Select-Object -ExpandProperty Item | Sort-Object -Unique))
    )

    return $DynamicParameters
  }
  
  begin {
    $AcquirerParams = @{}
    if ($psboundparameters.ContainsKey("Category")) {
      $AcquirerParams.Add("Category", $psboundparameters['Category'])
    }
    if ($psboundparameters.ContainsKey("Item")) {
      $AcquirerParams.Add("Item", $psboundparameters['Item'])
    }
    $Acquirer = Get-KSInventoryAcquirer @AcquirerParams | Where-Object { $_.CmdLet }
  }
  
  process {
    Get-ChildItem "$CMDBPath\$Name.xml" | ForEach-Object {
      $AssetName = $_.BaseName

      Write-KSLog "$($AssetName)"
      
      $XPathNavigator = New-KSXPathNavigator $_.FullName -Mode Write
      $AssetNode = $XPathNavigator.Select("/Asset")
      $DeviceType = $AssetNode.Select("./General/DeviceTypes") | ConvertFrom-KSXPathNode -ToArray
      
      $Acquirer |
        Where-Object { ($DeviceType -and $DeviceType -contains $_.AppliesToDeviceType) -or -not $_.AppliesToDeviceType } |
        Where-Object { Get-Command $_.CmdLet } |
        ForEach-Object {
       
          $XmlFragment = $null
        
          $Parameters = $_.Parameters
          $ThisItem = $_.Item
          $ThisCategory = $_.Category
          
          $CategoryNode = $XPathNavigator.Select("/Asset/$ThisCategory")
          if (($CategoryNode | Measure-Object).Count -lt 1) {
            $AssetNode.AppendChild("<$ThisCategory />")
            $CategoryNode = $XPathNavigator.Select("/Asset/$ThisCategory")
          }
          
          $ItemNode = $XPathNavigator.Select("/Asset/$ThisCategory/$ThisItem")
          if (($ItemNode | Measure-Object).Count -lt 1) {
            $CategoryNode.AppendChild("<$ThisItem />")
            $ItemNode = $XPathNavigator.Select("/Asset/$ThisCategory/$ThisItem")
          }
          
          $ShouldRefresh = $false
          if ($Force -or -not $ItemNode.GetAttribute("LastUpdate", "")) {
            $ShouldRefresh = $true
          } elseif ($_.RefreshInterval -and $_.RefreshInterval -ne 'Never') {
            if ((Get-Date $ItemNode.GetAttribute("LastUpdate", "")) -lt ((Get-Date) - [TimeSpan]$_.RefreshInterval)) {
              $ShouldRefresh = $true
            }
          } elseif (-not $_.RefreshInterval) {
            if ((Get-Date $ItemNode.GetAttribute("LastUpdate", "")) -lt ((Get-Date) - $DefaultRefreshInterval)) {
              $ShouldRefresh = $true
            }
          }
          
          if ($ShouldRefresh) {
            Write-KSLog "  $ThisCategory\$($ThisItem): Updating"
          
            $PassedParameters = @{}
            $Parameters.Keys | ForEach-Object {
              $Value = $Parameters[$_]
              if ($Value -match '^%.+%$') {
                $XPathNode = $XPathNavigator.Select(($Value.Trim('%') -replace '\\', '/'))
                $Value = $XPathNode | ConvertFrom-KSXPathNode -ToObject
                if (-not ($Value | Get-Member -MemberType NoteProperty, Property -ErrorAction SilentlyContinue)) {
                  $Value = $XPathNode | ConvertFrom-KSXPathNode
                }
              }
              if ($Value) {
                $PassedParameters.Add($_, $Value)
              }
            }
            
            # Prepare an output pipeline operation.
            $OutputPipeline = $_.OutputPipeline
            if ($OutputPipeline -and $OutputPipeline -notmatch '^\|') {
              $OutputPipeline = "| $OutputPipeline"
            }
            
            # Prepare a script block to execute the requested CmdLet.
            $ScriptBlock = [ScriptBlock]::Create("
              param(
                [HashTable]`$Parameters,
                
                `$Properties
              )
              
              if (`$Properties) {
                $($_.CmdLet) @Parameters $OutputPipeline | Select-Object `$Properties
              } else {
                $($_.CmdLet) @Parameters $OutputPipeline
              }
            ")
            
            $ScriptError = $null
            if ($_.IsMultiValue) {
              if ($_.ItemName) {
                $ChildNodeName = $_.ItemName
              } else {
                $ChildNodeName = $ThisItem.TrimEnd("s")
              }
              try {
                $XmlFragment = Invoke-Command $ScriptBlock -ArgumentList $PassedParameters, $_.Properties -ErrorAction Stop | ConvertTo-KSXml -RootNodeName $ThisItem -ChildNodeName $ChildNodeName 
              } catch {
                $ScriptError = $_
              }
              $XmlFragment = ([XML]$XmlFragment).InnerXml
            } else {
              try {
                $XmlFragment = Invoke-Command $ScriptBlock -ArgumentList $PassedParameters, $_.Properties -ErrorAction Stop | ConvertTo-KSXml -RootNodeName $ThisCategory -ChildNodeName $ThisItem
              } catch {
                $ScriptError = $_
              }
              $XmlFragment = ([XML]$XmlFragment).$ThisCategory.InnerXml
            }

            if (-not $ScriptError -and $XmlFragment -and $XmlFragment -notmatch ' />$') {
              $ItemNode.ReplaceSelf($XmlFragment)
              Set-KSXPathAttribute -AttributeName "LastUpdate" -Value (Get-Date).ToLocalTime().ToString("u") -XmlNode $ItemNode
              Set-KSXPathAttribute -AttributeName "LastSuccessfulUpdate" -Value (Get-Date).ToLocalTime().ToString("u") -XmlNode $ItemNode
              Set-KSXPathAttribute -AttributeName "LastStatus" -Value "OK" -XmlNode $ItemNode
            }
            if ($ScriptError) {
              Set-KSXPathAttribute -AttributeName "LastUpdate" -Value (Get-Date).ToLocalTime().ToString("u") -XmlNode $ItemNode
              Set-KSXPathAttribute -AttributeName "LastStatus" -Value "Error" -XmlNode $ItemNode
              
              $ScriptError | ForEach-Object {
                Write-KSLog "  $ThisCategory\$($ThisItem): $($_.Exception.Message)" -LogLevel Error
              }
            }
          } else {
            Write-KSLog "  $ThisCategory\$($ThisItem): Within no refresh interval."
          }
        }

      $XPathNavigator.UnderlyingObject.Save($_.FullName)
    }
  }
}