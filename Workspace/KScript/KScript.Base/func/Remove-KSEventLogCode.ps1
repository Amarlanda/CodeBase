function Remove-KSEventLogCode {
  # .SYNOPSIS
  #   Remove a set of saved event log codes.
  # .DESCRIPTION
  #   Remove-KSEventLogCode removes a saved set of Event Log codes reserved by KScript.
  # .PARAMETER Name
  #   The name of the script, module or a generic handle.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Remove-KSEventLogCode -Name SomeScript
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Name
  )

  process {
    $FileName = Get-KSSetting KSEventLogCodes -ExpandValue
    if (-not (Test-Path $FileName -PathType Leaf)) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object Exception "Unable to access global settings file ($FileName)."),
        "ResourceUnavailable",
        [Management.Automation.ErrorCategory]::ResourceUnavailable,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
 
    $XPathNavigator = New-KSXPathNavigator $FileName -Mode Write
    
    $XPathNode = $XPathNavigator.Select("/EventLogCodes/EventLogCode[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']")
   
    if (($XPathNode | Measure-Object).Count -gt 0) {
      $XPathNode.DeleteSelf()
    }
    
    $XPathNavigator.UnderlyingObject.Save($FileName)
  }
}