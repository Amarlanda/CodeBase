function Remove-KSSetting {
  # .SYNOPSIS
  #   Remove a global setting for KScript modules.
  # .DESCRIPTION
  #   Remove-KSGlobalSetting adds or changes specific global settings such as mail server names, module source locations, etc.
  # .PARAMETER Name
  #   The setting name to remove.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Remove-KSSetting -Name SmtpServer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     04/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidatePattern( '[A-Z0-9_]+' )]
    [ValidateNotNullOrEmpty()]
    [String]$Name
  )

  process {
    $FileName = "$psscriptroot\..\var\local-settings.xml"
 
    if (Test-Path $FileName) {
      $XPathNavigator = New-KSXPathNavigator $FileName -Mode Write
      $XPathNode = $XPathNavigator.Select("/Settings/Item[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']")

      if (($XPathNode | Measure-Object).Count -gt 0) {
        $XPathNode.DeleteSelf()
      }
    
      $XPathNavigator.UnderlyingObject.Save($FileName)
    }
  }
}