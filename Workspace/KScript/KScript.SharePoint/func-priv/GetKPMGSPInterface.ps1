function GetKPMGSPInterface {
  # .SYNOPSIS
  #   Get all known WSDL interface URLs.
  # .DESCRIPTION
  #   Internal use only.
  
  [CmdLetBinding()]
  param(
    [String]$InterfaceName = "*"
  )
  
  $XPathDocument = New-Object Xml.XPath.XPathDocument((Resolve-Path "$psscriptroot\..\var\spwd.xml"))
  $XPathNavigator = $XPathDocument.CreateNavigator()
  
  if ($InterfaceName -match '\*') {
    $XPathQuery = "/interfaces/interface[contains(name, $InterfaceName)]"
  } else {
    $XPathQuery = "/interfaces/interface[name='$InterfaceName']"
  }
  $XPathExpression = $XPathNavigator.Compile($XPathQuery)

  $XPathNavigator.Select($XPathExpression) | ForEach-Object {
    $Interface = New-Object Object
    $_.Select("./*") | ForEach-Object {
      # Property: <ValueFromXML>
      Add-Member $_.Name -MemberType NoteProperty -Value $_.TypedValue -InputObject $Interface
    }
    $Interface 
  }
}