function Get-KSEventLogCode {
  # .SYNOPSIS
  #   Get event log codes used by KScript scripts or modules.
  # .DESCRIPTION
  #   Get event log codes registered for a specific script or module.
  # .PARAMETER Name
  #   The name of a previously registered script.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Base.EventLogCode
  # .EXAMPLE
  #   Get-KSEventLogCode
  #
  #   List all registered codes.
  # .EXAMPLE
  #   Get-KSEventLogCode Script-Name
  #
  #   List codes registered to Script-Name.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     09/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [String]$Name
  )
  
  if (-not [Diagnostics.EventLog]::SourceExists("KScript")) {
    New-EventLog -LogName Application -Source KScript -ErrorAction SilentlyContinue
    if (-not $?) {
      Write-Warning "Get-KSEventLogCode: KScript event source does not exist."
    }
  }
  
  $FileName = Get-KSSetting KSEventLogCodes -ExpandValue
  if (-not $FileName -and -not (Test-Path $FileName -PathType Leaf)) {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object Exception "Unable to access global settings file ($FileName)."),
      "ResourceUnavailable",
      [Management.Automation.ErrorCategory]::ResourceUnavailable,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }

  if ($Name) {
    $XPathExpression = "/EventLogCodes/EventLogCode[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']"
  } else {
    $XPathExpression = "/EventLogCodes/EventLogCode"
  }
  
  $XPathNavigator = New-KSXPathNavigator -FileName $FileName

  $XPathNavigator.Select($XPathExpression) | ConvertFrom-KSXPathNode -ToObject
}