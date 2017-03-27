function Get-KSSMTPConfiguration {
  # .SYNOPSIS
  #   Get SMTP configuration for the script from the global configuration resource.
  # .DESCRIPTION
  #   Get-KSSMTPConfiguration stores script-specific SMTP information such as sender, recipient(s) and subject. The SMTP server used by KScript is stored in the global variable PSEmailServer exposed using Get/Set-KSSetting.
  # .PARAMETER Name
  #   The name of the script or a text handle used to identifying configuration.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Base.SmtpConfiguration
  # .EXAMPLE
  #   Get-KSSMTPConfiguration Publish-Report
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     24/07/2014 - Chris Dent - Fixed handling of null returns from the first XPath query.
  #     23/07/2014 - Chris Dent - First release.
  
  [CmdletBinding()]
  param(
    [String]$Name
  )
  
  $SMTPConfigurationFile = Get-KSSetting KSSMTPConfiguration -ExpandValue
  if ($SMTPConfigurationFile -and (Test-Path $SMTPConfigurationFile -PathType Leaf)) {
    $XPathNavigator = New-KSXPathNavigator -FileName $SMTPConfigurationFile
    
    if ($Name) {
      $XPathExpression = "/Reports/Report[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']"
    } else {
      $XPathExpression = "/Reports/Report"
    }

    $XPathNode = $XPathNavigator.Select($XPathExpression)
    
    $SMTPConfiguration = $XPathNode | ConvertFrom-KSXPathNode -ToObject
    if ($SMTPConfiguration) {
      $SMTPConfiguration.Recipients = $XPathNode.Select("./Recipients") | ConvertFrom-KSXPathNode -ToArray
      $SMTPConfiguration.PSObject.TypeNames.Add("KScript.Base.SmtpConfiguration")
      
      return $SMTPConfiguration
    }
  }
}