function Get-KSLog {
  # .SYNOPSIS
  #   Get active log files within the current session.
  # .DESCRIPTION
  #   Get active log files in use within the current session.
  # .PARAMETER Name
  #   The name of the caller (script, module or just a name) using this log.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Base.Log
  # .EXAMPLE
  #   Get-KSLog
  #
  #   Get all open log files in the current session.
  # .EXAMPLE
  #   Get-KSLog Import-Stuff
  #
  #   Get the open log file in use by the Import-Stuff script.
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

  if ($Script:ActiveLog) {
    if ($Name -and $Script:ActiveLog.Contains($Name)) {
      return $Script:ActiveLog[$Name]
    }
  
    return $Script:ActiveLog.Values.GetEnumerator()
  }
}