function Rename-KSAsset {
  # .SYNOPSIS
  #   Rename an existing asset file.
  # .DESCRIPTION
  #   Rename-KSAsset allows an asset to be renamed.
  # .PARAMETER Name
  #   The existing name of the asset file.
  # .PARAMETER NewName
  #   The new name of the asset file.
  # .PARAMETER NewFQDNOrIP
  #   The new FQDN or IP address value for the asset.
  # .PARAMETER CMDBPath
  #   The path to the directory holding CMDB information. By default, the setting KSCMDBPath is used (Get-KSSetting).
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Rename-KSAsset -Name SomeComputer -NewName SomeNewName -NewFQDNOrIP 1.2.3.4
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     20/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,

    [ValidateNotNullOrEmpty()]
    [String]$NewName,

    [ValidateNotNullOrEmpty()]
    [String]$NewFQDNOrIP,
    
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
  
  if ($psboundparameters.ContainsKey('NewName')) {
    if (Test-Path "$CMDBPath\$NewName.xml") {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object Exception "Asset file ($NewName) already exists."),
        "ResourceUnavailable",
        [Management.Automation.ErrorCategory]::ResourceUnavailable,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
  }
  
  $XPathNavigator = New-KSXPathNavigator "$CMDBPath\$Name.xml" -Mode Write
  $HasChanged = $false
  
  if ($psboundparameters.ContainsKey('NewName')) {
    if ($XPathNavigator.Select('/Asset/Ceneral/Name').Value -ne $NewName) {
      $XPathNavigator.Select('/Asset/General/Name').SetValue($NewName)
      $HasChanged = $true
    }
  }
  if ($psboundparameters.ContainsKey('NewFQDNOrIP')) {
    if ($XPathNavigator.Select('/Asset/Ceneral/FQDNOrIP').Value -ne $NewFQDNOrIP) {
      $XPathNavigator.Select('/Asset/General/FQDNOrIP').SetValue($NewFQDNOrIP)
    }
  }
  
  if ($HasChanged) {
    $XPathNavigator.UnderlyingObject.Save("$CMDBPath\$Name.xml")
  } else {
    Write-Verbose "No changes made to $Name."
  }
  if ($psboundparameters.ContainsKey('NewName')) {
    Rename-Item "$CMDBPath\$Name.xml" "$CMDBPath\$NewName.xml"
  }
}