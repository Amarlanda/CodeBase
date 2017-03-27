function Set-KSXPathAttribute {
  # .SYNOPSIS
  #   Set an attribute using the XPathNavigator object.
  # .DESCRIPTION
  #   Set-KSXPathAttribute expects an XML node iterator, the name of an attribute and the new value.
  #
  #   The XML node holding the attribute must be selected before requesting a change using Set-KSXPathAttribute.
  # .PARAMETER AttributeName
  #   The name of the attribute to set.
  # .PARAMETER Value
  #   The value to set.
  # .PARAMETER XmlNode
  #   An XmlNode selected using an XPathNavigator which may be created using New-KSXPathNavigator.
  # .INPUTS
  #   System.String
  #   System.Xml.XPath.XPathNavigator
  # .EXAMPLE
  #   $XPathNavigator = New-KSXPathNavigator file.xml
  #   $XPathNavigator.Select("/SomeRoot/SomeElement")
  #   Set-KSXPathAttribute -AttributeName "Test" -Value "NewValue" -XPathNavigator $XPathNavigator
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     09/12/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('Name')]
    [String]$AttributeName,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Value,

    [Parameter(ValueFromPipeline = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'MS.Internal.Xml.Cache.XPathDocumentNavigator' -or $_.PSObject.TypeNames -contains 'System.Xml.DocumentXPathNavigator' } )]
    $XmlNode
  )
  
  process {
    $XPathNavigator = $XmlNode.CreateNavigator()

    if ($XPathNavigator.GetAttribute($AttributeName, "") -ne $Value) {
      if ($XPathNavigator.MoveToAttribute($AttributeName, "")) {
        $XPathNavigator.SetValue($Value)
        $XPathNavigator.MoveToParent() | Out-Null
      } else {
        $XPathNavigator.CreateAttribute("", $AttributeName, "", $Value)
      }
    }
  }
}