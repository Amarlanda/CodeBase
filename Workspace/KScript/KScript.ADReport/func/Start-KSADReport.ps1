function Start-KSADReport {
  # .SYNOPSIS
  #   Start and distribute scheduled reports.
  # .DESCRIPTION
  #   Start-KSADReport manages the execution of scheduled AD reports.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     12/08/2014 - Chris Dent - Fixed working directory.
  #     15/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'Scheduled')]
  param(
    [Parameter(ParameterSetName = 'Summary')]
    [Switch]$PublishSummary,
    
    [String]$WorkingDirectory = $PWD.Path
  )
  
  Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript
  
  if ($PublishSummary) {
    #
    # Summary (all reports)
    #
  
    Write-KSLog "Generating summary report"
  
    Get-KSADReport -Enabled | Publish-KSADReport -FileName "$WorkingDirectory\ADReport.xlsx" -Recipients "chris.dent@kpmg.co.uk"
  } else {
    #
    # Schedule processing
    #
    
    $SchedulerPath = Get-KSSetting ADSchedulerPath -ExpandValue
    if (-not $SchedulerPath) {
      Write-KSLog "ADSchedulerPath not set." -LogLevel Error
      break
    }
    
    # Import the scheduler
    $Scheduler = @{}
    if (Test-Path $SchedulerPath) {
      Import-Csv $SchedulerPath | ForEach-Object {
        $Scheduler.Add($_.ID, (Get-Date $_.LastRunTime))
      }
    }

    # Prevent invocation failures due to minor time mismatching.
    $ThisRunTime = Get-Date
    
    # Group by recipients
    
    Get-KSADReport -Enabled | ForEach-Object {
      $RunReport = $false
      if ($Scheduler.Contains($_.ID)) {
        $LastRun = $Scheduler[$_.ID]
        $NextRun = switch ($Report.Frequency) {
          'Daily'     { $LastRun.AddDays(1); break }
          'Weekly'    { $LastRun.AddDays(7); break }
          'Monthly'   { $LastRun.AddMonths(1); break }
          'Quarterly' { $LastRun.AddMonths(3); break }
          'Yearly'    { $LastRun.AddYears(1); break }
        }

        Write-KSLog "Publish-KSADReport: $($Report.ID) next scheduled on $NextRun"
        
        if ($NextRun -le (Get-Date)) {
          $RunReport = $true
        }
      } else {
        $RunReport = $true
      }
      
      Write-KSLog "Generating report: $($_.ID)"
      
      # Publish-KSADReport -Report $_ -FileName "$WorkingDirectory\ADReport.xlsx" -Recipients $_.Recipients
      
      Write-KSLog "Report complete: $($_.ID)"
      
      if ($RunReport) {
        $_ | Select-Object ID, @{n='LastRunTime';e={ $ThisRunTime }}
      } else {
        $_ | Select-Object ID, @{n='LastRunTime';e={ $Scheduler[$_.ID] }}
      }
    } | Export-Csv $SchedulerPath -NoTypeInformation
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}