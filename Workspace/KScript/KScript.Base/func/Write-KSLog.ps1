function Write-KSLog {
  # .SYNOPSIS
  #   Write a message to the event log or a log file (or both).
  # .DESCRIPTION
  #   Write-Log standardises and simplifies log file use, providing a single interface for functions and scripts to use.
  #
  #   Write-Log allows multiple calling scripts to write to independent log destinations without each needing to create and track its own log names.
  #
  #   If a log destination does not exist it will be created, and an active log file registered, the first time Write-KSLog is called.
  #
  #   Log files created by Write-KSLog are delimited text files. Message text is quoted to allow handling of line-breaks.
  # .PARAMETER DateFormat
  #   Log file messages have a date string appended. The format of the string is yyyy-MM-dd HH:mm:ss by default. An alternative format may be specified using this parameter.
  # .PARAMETER Delimiter
  #   Log file messages are delimited and the message is quoted to ensure log files can be read by tools like Import-Csv.
  #
  #   By default the delimiter is tab, an alternative delimiter may be specified.
  # .PARAMETER EventLog
  #   Send the message to the application Event Log using KScript as a source. EventLog codes will be automatically retrieved using Get-KSEventLogCode, if no specific codes are registered the default set will be used.
  # .PARAMETER LogLevel
  #   By default messages are logged as Information. Either of Warning or Error may be selected instead.
  # .PARAMETER Message
  #   A message to append to a log file or send to the Event Log.
  # .PARAMETER Name
  #   The name of the caller (script, module or just a name) using this log. If this function is called from another function Name will be automatically filled from the call stack. Name is mandatory when using this function from a RunSpace.
  # .PARAMETER Tee
  #   Log messages may be written to both a log file and the Event Log using the Tee parameter.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   C:\PS> function Import-Stuff {
  #   >>   Write-Log "Hello"
  #   >> }
  #
  #   A log is automatically created and the line Hello is written. The log file will stay open until either the PS session ends or Close-KSLog is used.
  # .EXAMPLE
  #   Write-Log "Hello" -Name "NewLog"
  #
  #   A log file is created based on the name NewLog. NewLog may be used as a handle to write further requests to the same file.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/08/2014 - Chris Dent - Added Transcript logging.
  #     24/07/2014 - Chris Dent - Added Write-Verbose/Warning/Error.
  #     14/07/2014 - Chris Dent - Added DateFormat and Delimiter parameters.
  #     09/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'ToFile')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Message,
  
    [Parameter(Position = 2)]
    [String]$Name,
    
    [Parameter(ParameterSetName = 'ToEventLog')]
    [Parameter(ParameterSetName = 'Tee')]
    [Switch]$EventLog,

    [ValidateSet('Information', 'Warning', 'Error')]
    [Alias('Level')]
    [String]$LogLevel = "Information",

    [Parameter(ParameterSetName = 'Tee')]
    [Switch]$Tee,
    
    [Switch]$StartTranscript,
    
    [Switch]$StopTranscript,
    
    [String]$DateFormat = "yyyy-MM-dd HH:mm:ss",
    
    [String]$Delimiter = "`t"
  )

  begin {
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
    
    $ActiveLog = Get-KSLog $Name
    if (-not $ActiveLog) {
      $ActiveLog = NewKSLog $Name
    }
  }
  
  process {
    switch ($LogLevel) {
      'Information' { Write-Verbose "$($Name): $Message" }
      'Warning'     { Write-Warning "$($Name): $Message" }
      'Error'       { Write-Error "$($Name): $Message" }
    }
  
    if ($StartTranscript -and $ActiveLog.TranscriptFile) {
      Start-Transcript -Path $ActiveLog.TranscriptFile -Append -ErrorAction SilentlyContinue -ErrorVariable TranscriptError
      if (-not $?) {
        Write-KSLog "$($TranscriptError.Exception.Message.Trim())" -Name $Name -LogLevel Error
      }
    } elseif ($StartTranscript) {
      Write-KSLog "Transcript log path not set (KSTranscriptLogPath). Transcript logging cannot be started." -Name $Name -LogLevel Warning
    }
    if ($StopTranscript) {
      Stop-Transcript
    }
  
    if (($EventLog -or $Tee) -and $ActiveLog.EventLogCodes) {
      if ([Diagnostics.EventLog]::SourceExists("KScript")) {
        Write-EventLog -LogName Application -Source KScript -EventID $ActiveLog.EventLogCodes.$LogLevel -EntryType $LogLevel -Message $Message
      } elseif ($ActiveLog.LogFile) {
        # Attempt to pass this error back in and write it to the callers log file.
        $ErrorMessage = "Write-KSLog: Failed to write EventLog message. KScript event source does not exist and must be created."
        $ErrorMessage | Write-KSLog -Name $Name
        Write-Error $ErrorMessage -Category OperationStopped
      }
    }
    
    if ((-not $EventLog -or $Tee) -and $ActiveLog.LogFile) {
      "$(Get-Date -Format $DateFormat)$Delimiter$($LogLevel.ToUpper())$Delimiter""$Message""" | 
        Out-File $ActiveLog.LogFile -Append -Encoding ASCII
    }
  }
}