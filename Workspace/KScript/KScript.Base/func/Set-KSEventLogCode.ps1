function Set-KSEventLogCode {
  # .SYNOPSIS
  #   Set event log codes for use by a handle.
  # .DESCRIPTION
  #   Set-KSEventLogCode allows the modification of existing codes or the definition of a new set of event log codes for a handle. The handle may be a script name, module name or an arbitrary string.
  #
  #   Codes are assigned as follows:
  #
  #    * Information codes start from 1000
  #    * Warning codes start from 3000
  #    * Error codes start from 5000
  #
  #   New codes are automatically created if no values are specified. New codes are generated using the following steps:
  #
  #     1. Get all existing codes
  #     2. Find the highest number above the starting point for each individual code
  #     3. Generate a new code-set based on the highest number returned
  #
  #   For example, the codes 1042, 3042 and 5042 (for Information, Warning and Error respectively) will be generated if the highest previously allocated codes for each are 1004, 3041 and 5040.
  #
  #   Event log codes may be reused (if removed), and handles may share codes. Reuse will not happen automatically unless the highest code is removed.
  #
  #   Set-KSEventLogCode will attempt to register KScript as an Application event source if it has not already been registered.
  # .PARAMETER Name
  #   The name of the new script, module or a generic handle.
  # .PARAMETER Information
  #   The log code to use for Information messages.
  # .PARAMETER Warning
  #   The log code to use for Warning messages.
  # .PARAMETER Error
  #   The log code to use for Error messages.
  # .INPUTS
  #   System.String
  #   System.UInt32
  # .EXAMPLE
  #   Set-KSEventLogCode -Name "KScript.Base" -Information 1020
  #
  #   Register event log codes for use with KScript.Base.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     09/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'Automatic')]
  param(
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
    [UInt32]$Information,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
    [UInt32]$Warning,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'Manual')]
    [UInt32]$Error
  )
  
  if (-not [Diagnostics.EventLog]::SourceExists("KScript")) {
    New-EventLog -LogName Application -Source KScript -ErrorAction SilentlyContinue
    if (-not $?) {
      Write-Warning "Get-KSEventLogCode: KScript event source does not exist."
    }
  }

  $FileName = Get-KSSetting KSEventLogCodes -ExpandValue
  if (-not (Test-Path $FileName -PathType Leaf)) {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object Exception "Unable to access global settings file ($FileName)."),
      "ResourceUnavailable",
      [Management.Automation.ErrorCategory]::ResourceUnavailable,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
  
  if ($pscmdlet.ParameterSetName -eq 'Automatic') {
    # Generate Information, Warning and Error codes (as an increment of the highest modulus)
    $Offset = 0
    Get-KSEventLogCode | ForEach-Object {
      $CodeSet = $_
      'Information', 'Warning', 'Error' | ForEach-Object {
        $Modulus = $CodeSet.$_ % 1000
        if ($Modulus -gt $Offset) {
          $Offset = $Modulus
        }
      }
    }
    # Increment the offset 
    $Offset = $Offset++
    
    $Information = 1000 + $Offset
    $Warning = 3000 + $Offset
    $Error = 5000 + $Offset
  }
  
  $XPathNavigator = New-KSXPathNavigator -FileName $FileName -Mode Write

  $XPathNode = $XPathNavigator.Select("/EventLogCodes/EventLogCode[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']")

  if (($XPathNode | Measure-Object).Count -gt 0) {
    $EventLogCode = $XPathNode | ConvertFrom-KSXPathNode
    
    'Information', 'Warning', 'Error' | ForEach-Object {
      if ($psboundparameters.ContainsKey($_) -and $EventLogCode.$_ -ne (Get-Variable $_).Value) {
        $XPathNode.Select("./$_").SetValue((Get-Variable $_).Value)
      }
    }
  } else {
    $XPathNavigator.Select("/EventLogCodes").AppendChild(
      "<EventLogCode><Name>$Name</Name><Information>$Information</Information><Warning>$Warning</Warning><Error>$Error</Error></EventLogCode>"
    )
  }
  
  $XPathNavigator.UnderlyingObject.Save($FileName)

  if ($PassThru) {
    Get-KSEventLogCode -Name $Name
  }
}