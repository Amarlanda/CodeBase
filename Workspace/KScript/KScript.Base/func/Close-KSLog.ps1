function Close-KSLog {
  # .SYNOPSIS
  #   Close an existing log file.
  # .DESCRIPTION
  #   Close-KSLog shuts down an active log file, allowing a new log file to be created.
  #
  #   Close-KSLog is only necessary when changing logs within a session. References to log files are removed when a PowerShell session is closed.
  # .PARAMETER Name
  #   The name of the caller (script, module or just a name) using this log. If this function is called from another function Name will be automatically filled from the call stack. Name is mandatory when using this function from a RunSpace.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Close-KSLog Import-Stuff
  #
  #   Close the reference to the log file used by Import-IPPhone.
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

  if (-not $Name -and $myinvocation.CommandOrigin -eq [Management.Automation.CommandOrigin]::Internal) {
    $Name = (Get-PSCallStack)[1].Command
  } elseif (-not $Name) {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object ArgumentException "Name must be set when called from RunSpace."),
      "ArgumentException",
      [Management.Automation.ErrorCategory]::InvalidArgument,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
  
  if ($Script:ActiveLog -and $Script:ActiveLog.Contains($Name)) {
    $Script:ActiveLog.Remove($Name)
  }
}