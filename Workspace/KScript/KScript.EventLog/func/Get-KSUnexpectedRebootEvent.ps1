function Get-KSUnexpectedRebootEvent {
  # .SYNOPSIS
  #   Get unexpected reboot events.
  # .DESCRIPTION
  #   Gets unexpected reboot events (Event ID 6008) and attempts to correlate administrative acknowledgement (Event ID 1076) and any bug check messages (Event ID 1001). Event correlation is best-effort and may not be correct.
  #
  #   The event log query is run as parallel jobs. Pseudo-threading is managed by the function using *-Job.
  # .PARAMETER ComputerName
  #   An ComputerName to query. If ComputerName is not specified Get-KSUnexpectedRebootEvent queries the local computer.
  #
  #   ComputerName accepts pipeline input, however jobs will only be effective if the value supplied to ComputerName is an array.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.EventLog.UnexpectedRebootEvent
  # .EXAMPLE
  #   Get-KSUnexpectedRebootEvent
  # .EXAMPLE
  #   Get-KSUnexpectedRebootEvent -ComputerName $env:ComputerName, ukvmssrv143
  # .EXAMPLE
  #   Get-KSUnexpectedRebootEvent -After ((Get-Date).AddMonths(-6))
  #
  #   Show unexpected reboot events and associated acknowledgements and bug-checks for the last 6 months.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     30/10/2014 - Chris Dent - BugFix: CmdLet name changes.
  #     17/06/2014 - Chris Dent - Redesigned, fixed error handling and added a wrapper for Get-WinEvent.
  #     05/06/2014 - Chris Dent - First release.
    
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [String[]]$ComputerName = $env:ComputerName,

    [DateTime]$After,
    
    [ValidateRange(1, 50)]
    [UInt32]$JobLimit = 10
  )
  
  begin {
    $EventQueryScriptBlock = {
      [CmdLetBinding()]
      param(
        [Parameter(Position = 1)]
        [String]$ComputerName,
        
        [Parameter(Position = 2)]
        [System.Nullable``1[[System.DateTime]]]$After
      )

      $Events = @()
      
      # Attempt to do this using Get-WinEvent.
      #
      # Get-WinEvent has far better filtering options and is faster than Get-EventLog, however Get-WinEvent can only be used against
      # Windows Vista and Windows 2008 or newer. If the CmdLet cannot be used the RPC endpoint mapper will return a specific error.
      $FilterHashtable = @{LogName = 'System'}
      if ($After) { $FilterHashtable.Add("StartTime", $After) }
      
      # Attempt the process using Get-WinEvent. Note: Get-WinEvent may not return a message when the system culture is not set to en-US.
      # Invoke-KSGetWinEvent wraps around Get-WinEvent, changing the culture backwards and forwards as appropriate.
      $FilterHashtable.Add("ID", 6008) # Unexpected reboot
      try {
        # Drop After from the parameter set, it can only be used in the FilterHashtable.
        $BoundParameters = @{}
        if ($psboundparameters.ContainsKey('ComputerName')) {
          $BoundParameters.Add('ComputerName', $psboundparameters['ComputerName'])
        }

        $Events += Invoke-KSGetWinEvent -FilterHashtable $FilterHashtable -ErrorAction SilentlyContinue @BoundParameters
      } catch [Diagnostics.Eventing.Reader.EventLogException] {
        if ($_.Exception.Message -eq 'There are no more endpoints available from the endpoint mapper') {
          Write-Warning "Get-KSUnexpectedRebootEvent :: $($ComputerName): Get-WinEvent is not supported, switching to Get-EventLog."
          $UseGetEventLog = $true
        } else {
          # Return a non-terminating error.
          $ErrorMessage = "Get-KSUnexpectedRebootEvent :: $($ComputerName): Get-WinEvent: $($_.Exception.Message)"
          Write-Error $ErrorMessage -Category ConnectionError
        }
      } catch {
        # Return all others as terminating
        $ErrorRecord = New-Object Management.Automation.ErrorRecord(
          $_.Exception,
          $_.Exception.Message.ToString(),
          [Management.Automation.ErrorCategory]::NotSpecified,
          [Management.Automation.PSCmdLet])
        $pscmdlet.ThrowTerminatingError($ErrorRecord)
      }
      
      if ($Events) {
        # Executed only if the original Get-WinEvent call succeeded. Get events which may provide evidence.
        $FilterHashtable.ID = 1076 # Unexpected reboot acknowledgement
        $Events += Invoke-KSGetWinEvent -FilterHashtable $FilterHashtable -ErrorAction SilentlyContinue @BoundParameters

        $FilterHashtable.ID = 1001 # Bug-check
        $Events += Invoke-KSGetWinEvent -FilterHashtable $FilterHashtable -ErrorAction SilentlyContinue @BoundParameters
        
        $Events = $Events | Select-Object MachineName, ID, LevelDisplayname, Message, TimeCreated
      }
      
      if ($UseGetEventLog) {
        # InstanceID and EventID are loosely correlated, this is a best-guess method of capturing these events.
        #   1073742825 = Bug-check (EventID 1001)
        #   2147484724 = Unexpected reboot acknowledgement (EventID 1076)
        #   2147489656 = Unexpected reboot (EventID 6008)
        #
        # Properties are made to match those returned by Get-WinEvent.
        $Events = Get-EventLog -LogName System -InstanceId 1073742825, 2147484724, 2147489656 @PSBoundParameters |
          Select-Object MachineName, @{n='ID';e={ $_.EventId }}, @{n='LevelDisplayName';e={ $_.EntryType }}, Message, @{n='TimeCreated';e={ TimeGenerated }}
      }
      
      # Begin processing the returned logs.
      if ($Events) {
        $Events = $Events | Sort-Object TimeCreated -Descending | Group-Object ID -AsHashtable

        $LastRebootEventTime = Get-Date
        $Events[6008] | ForEach-Object {
          # Lower bound for acknowledgement message
          $RebootEventTime = $_.TimeCreated
         
          $Acknowledgement = $Events[1076] | Where-Object { $_.TimeCreated -gt $RebootEventTime -and $_.TimeCreated -lt $LastRebootEventTime }
          # Attempt to see if there may be a bug-check associated with this reboot. Loose / speculative event association.
          # The last of these events will be closest to $RebootEventTime because of the Sort executed above.
          $Bugcheck = $Events[1001] | 
            Where-Object { $_.TimeCreated -gt $RebootEventTime -and $_.TimeCreated -lt $LastRebootEventTime } |
            Select-Object -Last 1
          
          $_ | Select-Object *,
              @{n='AcknowledgementMessage';e={ $Acknowledgement.Message }},
              @{n='AcknowledgementTime';e={ $Acknowledgement.TimeCreated }},
              @{n='BugcheckMessage';e={ $Bugcheck.Message }},
              @{n='BugcheckTime';e={ $Bugcheck.TimeCreated }} |
            ForEach-Object {
              # Tag the object with a type name.
              $_.PSObject.TypeNames.Add("KScript.EventLog.UnexpectedRebootEvent")
              
              # Return the object
              $_
            }
          
          # Upper bound for acknowledgement message
          $LastRebootEventTime = $RebootEventTime
        }
      } else {
        Write-Verbose "Get-KSUnexpectedRebootEvent :: $($ComputerName): No unexpected reboot events found."
      }
    }
  }
  
  process {
    if ($ComputerName.Count -eq 1) {
      Invoke-Command -ScriptBlock $EventQueryScriptBlock -ArgumentList $ComputerName[0], $After
    } else {
      $Jobs = @()
      $ComputerName | ForEach-Object {
      
        Write-Progress -Activity "Starting query job" -Status "ComputerName: $_"
      
        while ((Get-Job -State Running | Measure-Object).Count -ge $JobLimit) {
          Write-Progress -Activity "Sleeping" -Status "Waiting to start query on $_"
          Start-Sleep -Seconds 10
        }
      
        $ArgumentList = @($_)
        if ($After) { $ArgumentList += $After }
        $Jobs += Start-Job -ScriptBlock $EventQueryScriptBlock -ArgumentList $ArgumentList
      }
      
      # This needs some kind of count-down
      do {
        $RunningJobs = Get-Job -State Running
        
        Write-Progress "Waiting for jobs to complete" -Status "Job ($($RunningJobs.Count)/$($Jobs.Count))"
        
      } until (-not $RunningJobs)
    
      Get-Job | Receive-Job | Select-Object * -ExcludeProperty RunspaceId, PSComputerName, PSShowComputerName
     
      # Cleanup
      Get-Job | Remove-Job
    }
  }
}