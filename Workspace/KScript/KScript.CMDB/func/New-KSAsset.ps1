function New-KSAsset {
  # .SYNOPSIS
  #   Register a new asset with the CMDB.
  # .DESCRIPTION
  #   Add a new asset record for the specificed Name and FQDN or IP address.
  # .PARAMETER CMDBPath
  #   The path to the CMDB repository.
  # .PARAMETER DeviceType
  #   Define a DeviceType for the asset. If DeviceType is set only Inventory Items applicable to that device type will be executed (if the Inventory Item defines a DeviceType).
  #
  #   By default DeviceType is assumed to be MicrosoftWindows.
  # .PARAMETER Force
  #   Overwrite any existing asset file of the same name.
  # .PARAMETER FQDNOrIP
  #   The FQDN is used for all acquirers which require a name or IP to connect to. 
  # .PARAMETER Name
  #   The friendly name of the asset, typically a computername. The Name property will be used to attempt to find associated accounts for the asset in Active Directory.
  # .PARAMETER UpdateAsset
  #   Attempt to update the asset information.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   New-KSAsset -Name SomeComputer -FQDNOrIP SomeComputer.domain.example
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     18/11/2014 - Chris Dent - Modified DeviceType to support multiple types.
  #     05/11/2014 - Chris Dent - Added DeviceType.
  #     04/11/2014 - Chris Dent - Made Update-KSAsset optional (UpdateAsset parameter).
  #     29/10/2014 - Chris Dent - BugFix: Passed CMDBPath to Update-KSAsset.
  #     23/10/2014 - Chris Dent - Made Name and FQDNOrIP lower case for consistency.
  #     21/10/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$FQDNOrIP,
    
    [ValidateNotNullOrEmpty()]
    [String]$DeviceType = "MicrosoftWindows",
    
    [Switch]$Force,
    
    [Boolean]$UpdateAsset = $true,
    
    [ValidateNotNullOrEmpty()]
    [String]$CMDBPath = (Get-KSSetting KSCMDBPath -ExpandValue)
  )
  
  if (-not (Test-Path "$CMDBPath\$Name.xml") -or $Force) {
    $Name = $Name.ToLower()
    $FQDNOrIP = $FQDNOrIP.ToLower()
  
    $StringBuilder = New-Object Text.StringBuilder
    
    $XmlWriterSettings = New-Object Xml.XmlWriterSettings
    $XmlWriterSettings.Indent = $true
   
    $XmlWriter = [Xml.XmlWriter]::Create($StringBuilder, $XmlWriterSettings)
    $XmlWriter.WriteStartElement("Asset")
   
    $XmlWriter.WriteStartElement("General")
    
    $XmlWriter.WriteStartElement("Name")
    $XmlWriter.WriteString($Name)
    $XmlWriter.WriteEndElement()
    
    $XmlWriter.WriteStartElement("FQDNOrIP")
    $XmlWriter.WriteString($FQDNOrIP.ToLower())
    $XmlWriter.WriteEndElement()
   
    if ($psboundparameters.ContainsKey("DeviceType")) {
      $XmlWriter.WriteStartElement("DeviceTypes")
      $XmlWriter.WriteStartElement("DeviceType")
      $XmlWriter.WriteString($DeviceType)
      $XmlWriter.WriteEndElement()
      $XmlWriter.WriteEndElement()
    }
   
    # General
    $XmlWriter.WriteEndElement()
    
    # Asset
    $XmlWriter.WriteEndElement()
    
    $XmlWriter.Flush()
   
    $StringBuilder.ToString() | Out-File "$CMDBPath\$Name.xml" -Force
    
    if ($UpdateAsset) {
      Update-KSAsset -Name $Name -CMDBPath $CMDBPath
    }
  } else {
    Write-Warning "Inventory file ($Name) already exists. Please use the Force parameter to overwrite, Rename-KSAsset to update name or FQDN values, or Update-KSAsset to gather inventory information."
  }
}