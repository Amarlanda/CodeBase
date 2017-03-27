function Set-KSAsset {
  # .SYNOPSIS
  #   Set asset specific information for an existing asset file.
  # .DESCRIPTION
  #   Set-KSAsset allows the asset DeviceType list to be set for an asset.
  # .PARAMETER Name
  #   The name of the asset file.
  # .PARAMETER DeviceType
  #   Define a list of DeviceTypes for the asset. If DeviceTypes is set only Inventory Items applicable to the list of device types will be executed (if the Inventory Item defines AppliesToDeviceType).
  # .PARAMETER CMDBPath
  #   The path to the directory holding CMDB information. By default, the setting KSCMDBPath is used (Get-KSSetting).
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Set-KSAsset -Name SomeComputer -DeviceType MicrosoftWindows
  #
  #   Set the DeviceType to MicrosoftWindows.
  # .EXAMPLE
  #   Set-KSAsset -Name SomeComputer -DeviceType MicrosoftWindows, VirtualMachine
  #
  #   Set the DeviceType list to MicrosoftWindows and VirtualMachine.
  # .EXAMPLE
  #   Set-KSAsset -Name SomeComputer -DeviceType VirtualMachine -Append
  #
  #   Add VirtualMachine to the list of existing types.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/11/2014 - Chris Dent - BugFix: Append parameter.
  #     11/11/2014 - Chris Dent - Modified DeviceType to be multi-value.
  #     07/11/2014 - Chris Dent - Added AssetName alias to Name.
  #     05/11/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValuefromPipelineByPropertyName = $true)]
    [Alias('AssetName')]
    [String]$Name,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [String[]]$DeviceType,
    
    [Switch]$Append,

    [ValidateNotNullOrEmpty()]
    [String]$CMDBPath = (Get-KSSetting KSCMDBPath -ExpandValue)
  )
  
  if (-not (Test-Path "$CMDBPath\$Name.xml")) {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object Exception "Unable to access inventory file ($Name)."),
      "ResourceUnavailable",
      [Management.Automation.ErrorCategory]::ResourceUnavailable,
      $pscmdlet)  
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
  
  $XPathNavigator = New-KSXPathNavigator "$CMDBPath\$Name.xml" -Mode Write
  
  $DeviceTypeNode = $XPathNavigator.Select("/Asset/General/DeviceTypes")
  
  if (($DeviceTypeNode | Measure-Object).Count -lt 1) {
    $XPathNavigator.Select("/Asset/General").AppendChild("<DeviceTypes />")
    $DeviceTypeNode = $XPathNavigator.Select("/Asset/General/DeviceTypes")
  }

  $HasChanged = $false
  if ($Append) {
    $ExistingDeviceType = $DeviceTypeNode.Select("./DeviceType").Value
    $NewDeviceType = $DeviceType | Where-Object { $_ -notin $ExistingDeviceType } | Sort-Object
    
    if ($NewDeviceType) {
      $HasChanged = $true
      
      $NewDeviceType | ForEach-Object {
        $DeviceTypeNode.AppendChild("<DeviceType>$_</DeviceType>")
      }
    }
  } else {
    $HasChanged = $true
  
    $DeviceTypeXml = $DeviceType | Sort-Object | ForEach-Object { "<DeviceType>$_</DeviceType>" }
    $DeviceTypeNode.ReplaceSelf("<DeviceTypes>$DeviceTypeXml</DeviceTypes>")
  }
  
  if ($HasChanged) {
    $XPathNavigator.UnderlyingObject.Save("$CMDBPath\$Name.xml")
  } else {
    Write-Verbose "Set-KSAsset: No changes made to $Name."
  }
}
