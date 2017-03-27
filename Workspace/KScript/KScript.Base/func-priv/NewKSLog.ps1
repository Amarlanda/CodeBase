function NewKSLog {
  # .SYNOPSIS
  #   Create a new log file and retrieve event log codes.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   New-KSLog attempts to create a new log file and acquire event log codes for the specified script, module or handle.
  # .PARAMETER Name
  #   The name of the caller (script, module or just a name) using this log.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Base.Log
  # .EXAMPLE
  #   NewKSLog Import-Stuff
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/08/2014 - Chris Dent - Added transcript log file path generation.
  #     23/07/2014 - Chris Dent - Fixed CanWrite check.
  #     10/07/2014 - Chris Dent - Changed to private scope.
  #     09/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Name
  )
  
  if (-not $Script:ActiveLog) {
    New-Variable ActiveLog -Scope Script -Value @{}
  }
 
  if (-not $Script:ActiveLog.Contains($Name)) {
  
    # Create a log file to use.
  
    $LogPath = Get-KSSetting KSLogPath -ExpandValue
    if (-not $LogPath) {
      Write-Warning "New-KSLog: KSLogPath is not defined. Using $env:Temp"
      $LogPath = $env:Temp
    }
    $LogPath = $LogPath.TrimEnd('\')
  
    $CanWrite = $true
    do {
      $LogFile = "$LogPath\$Name.$(Get-Date -Format 'yyyyMMdd').log"
      if (Test-Path $LogFile -PathType Leaf) {
        $LogFileItem = Get-Item $LogFile
        # Test write access
        try {
          $LogFileStream = $LogFileItem.OpenWrite()
        } catch [UnauthorizedAccessException] {
          $CanWrite = $false
        }
        $LogFileStream.Close()
      } else {
        New-Item $LogFile -ItemType File -ErrorAction SilentlyContinue -Force | Out-Null
        if (-not $?) {
          $CanWrite = $false
        }
      }
      if (-not $CanWrite) {
        Write-Warning "New-KSLog: Unable to create log file under the specified path ($LogPath)."
        if ($LogPath -ne $env:Temp) {
          $LogPath = $env:Temp
        } else {
          $Abort = $true
        }
      }
    } until ($CanWrite -or $Abort)
    if (-not $CanWrite) { $LogFile = $null }
    
    # Get event log codes to use.
    
    $EventLogCodes = Get-KSEventLogCode $Name
    if (-not $EventLogCodes) {
      $EventLogCodes = Get-KSEventLogCode default
    }
    $EventLogCodes = $EventLogCodes | Select-Object * -ExcludeProperty Name
    
    # Generate a transaction log file name.
    
    $TranscriptLogPath = Get-KSSetting KSTranscriptLogPath -ExpandValue
    if ($TranscriptLogPath) {
      $TranscriptFile = "$TranscriptLogPath\$Name.$(Get-Date -Format 'yyyyMMdd').txt"
    }
    
    $Log = New-Object PSObject -Property ([Ordered]@{
      Name           = $Name
      LogFile        = $LogFile
      TranscriptFile = $TranscriptFile
      EventLogCodes  = $EventLogCodes
    })
    $Log.PSObject.TypeNames.Add("KScript.Base.Log")
    
    $Script:ActiveLog.Add($Name, $Log)
  }
  
  return (Get-KSLog $Name)
}