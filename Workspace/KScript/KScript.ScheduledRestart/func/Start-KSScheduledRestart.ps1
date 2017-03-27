function Start-KSScheduledRestart {
  # .SYNOPSIS
  #   Start a scheduled restart process of the computers specified in a schedule file.
  # .DESCRIPTION
  #   Start-KSScheduledRestart attempts to restart the servers defined in the default schedule file used by Get-KSScheduledRestart.
  #
  #   Start-KSScheduledRestart supports ordered restarts and dependency chains. If a server earlier in a dependency fails to restart the rest of the chain is dropped.
  # .PARAMETER ServiceProbeTimeout
  #   The service probe timeout allows the script to stop waiting for a service to restart.
  # .INPUTS
  #   System.TimeSpan
  # .EXAMPLE
  #   Start-KSScheduledRestart
  #
  #   Review the schedule file and process any services.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     14/10/2014 - Chris Dent - Swapped shutdown.exe for Restart-Computer.
  #     13/10/2014 - Chris Dent - BugFix: Daylight saving time adjustment.
  #     10/10/2014 - Chris Dent - Changed datetime string format.
  #     09/10/2014 - Chris Dent - BugFix: Return value from shutdown command.
  #     08/10/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [TimeSpan]$ServiceProbeTimeout = (New-TimeSpan -Minutes 5)
  )
  
  Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript
  
  $HostsToRestart = Get-KSScheduledRestart |
    Where-Object { $_.NextRestart -eq (Get-Date -Format 'yyyy-MM-dd HH:00:00') -and $_.HourOfDay -eq (Get-Date -Format 'HH') } |
    ForEach-Object {
      if ($_.RecordIsValid) {
        $_
      } else {
        Write-KSLog "ComputerName: $($_.ComputerName) - Scheduled to restart but unmanaged record modification found. Please correct the record using Add-KSScheduledRestart." -LogLevel Error
      }
    }
  
  if ($HostsToRestart) {
    $HostsToRestart | Group-Object Service | ForEach-Object {
      Write-KSLog "Service: $($_.Name)"
      
      $ProcessRestart = $true

      $_.Group | Group-Object Order | ForEach-Object {
        Write-KSLog "  Order: $($_.Name)"
        
        $_.Group | ForEach-Object {
          if ($ProcessRestart) {
            Write-KSLog "    ComputerName: $($_.ComputerName) - Executing system restart."
            
            if ($pscmdlet.ShouldProcess("Restarting $($_.ComputerName)")) {
              Update-KSScheduledRestart -ComputerName $_.ComputerName
              Restart-Computer -ComputerName $_.ComputerName -ErrorAction SilentlyContinue -ErrorVariable RestartError
              if ($RestartError) {
                Write-KSLog "    $($RestartError.Exception.Message.Trim() -replace '\n')" -LogLevel Error
              }
            }
          } else {
            Write-KSLog "    ComputerName: $($_.ComputerName) - Skipping system restart, dependency failed."
          }
        }
        
        # Sleep after the restart to ensure the servers have had time to go offline
        Start-Sleep -Seconds 60
        
        if ($ProcessRestart) {
          Write-KSLog "  Checking group:"
          
          # Create an object to hold the state of the probes
          $GroupProbeState = $_.Group |
            Select-Object ComputerName, ServiceProbe,
              @{n='IPAddress';e={ (Test-Connection $_.ComputerName -Count 1).IPv4Address }},
              @{n='ProbeState';e={ 'NoResponse' }} |
            Where-Object { $_.IPAddress }
          
          # Mark the probe start for the timeout.
          $ServiceProbeStart = Get-Date
          
          do {
            $GroupProbeState | Where-Object { $_.ProbeState -eq 'NoResponse' } | ForEach-Object {
              if ($_.ServiceProbe -eq 'ICMP') {
                if (Test-Connection $_.ComputerName -Quiet -Count 1) {
                  $_.ProbeState = 'Responding'
                  Write-KSLog "    ComputerName: $($_.ComputerName) - Responding"
                }
              } else {
                if (Test-TcpPort -IPAddress $_.IPAddress -Port $_.ServiceProbe) {
                  $_.ProbeState = 'Responding'
                  Write-KSLog "    ComputerName: $($_.ComputerName) - Responding"
                }
              }
            }
            $FailedProbes = $GroupProbeState | Where-Object { $_.ProbeState -eq 'NoResponse' }
            if ($FailedProbes) {
              # Sleep for 30 seconds and try polling (unresponsive) services again
              Start-Sleep -Seconds 30
            }
          } until ($FailedProbes -eq $null -or (Get-Date) -ge ($ServiceProbeStart + $ServiceProbeTimeout))
          
          $GroupProbeState | Where-Object { $_.ProbeState -eq 'NoResponse' } | ForEach-Object {
            Write-KSLog "    ComputerName: $($_.ComputerName) - TimeOut waiting for service to respond"
            $ProcessRestart = $false
          }
        }
      }
    }
  }

  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}