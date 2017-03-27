function Get-KSTelephoneNumber {
  # .SYNOPSIS
  #   Get a telephoneNumber and otherTelephone based on the IPPhone value.
  # .DESCRIPTION
  #   Get-KSTelephoneNumber uses a ddi-mapping.xml file to attempt to find TelephoneNumber and OtherTelephone values for an IPPhone value.
  # .PARAMETER IPPhone
  #   An IPPhone value.
  # .PARAMETER MappingFile
  #   The path to the mapping file used to translate extensions to phone numbers.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Telephony.TelephoneNumber
  # .EXAMPLE
  #   Get-KSTelephoneNumber -IPPhone 87104385
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     27/11/2014 - Chris Dent - BugFix: Unintentional truncation of leading 0s in extension numbers.
  #     20/08/2014 - Chris Dent - Added mandatory flag to IPPhone parameter. Modified return to include OfficeName and a Status field.
  #     05/08/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('\d{8}')]
    [String]$IPPhone,
    
    [String]$MappingFile = "$psscriptroot\..\var\ddi-mapping.xml"
  )
  
  $TelephoneNumber = New-Object PSObject -Property ([Ordered]@{
    IPPhone         = $IPPhone
    TelephoneNumber = $null
    OtherTelephone  = $null
    OfficeName      = $null
    Status          = "OK"
  })
  $TelephoneNumber.PSObject.TypeNames.Add("KScript.Telephony.TelephoneNumber")

  if ($IPPhone -match '^870[789]') {
    $TelephoneNumber.Status = "Dummy range"
    
    return $TelephoneNumber
  }
  
  $OfficeCode = $IPPhone.SubString(1, 3)
  $Extension = $IPPhone.SubString(4, 4)
  $ExtensionUInt = [UInt32]$Extension
  
  $XPathNavigator = New-KSXPathNavigator $MappingFile

  $XPathExpression = "/DDIMappings/DDIMapping[OfficeCode='$OfficeCode' and FromExt <= $ExtensionUInt and ToExt >= $ExtensionUInt]"
  $DDIMapping = $XPathNavigator.Select($XPathExpression) | ConvertFrom-KSXPathNode -ToObject

  if (($DDIMapping | Measure-Object).Count -gt 1) {
    $TelephoneNumber.Status = "Too many possible DDI mappings for $IPPhone."
    
    return $TelephoneNumber
  } elseif ($DDIMapping) {
    $TelephoneNumber.TelephoneNumber = "$($DDIMapping.DDINumber)$Extension"
    $TelephoneNumber.OtherTelephone = "$OfficeCode $Extension"
    $TelephoneNumber.OfficeName = $DDIMapping.OfficeName
    
    return $TelephoneNumber
  } else {
    $TelephoneNumber.Status = "No matches"
    
    return $TelephoneNumber
  }
}