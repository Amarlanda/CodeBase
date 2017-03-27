function Update-KSScheduledRestart {
  # .SYNOPSIS
  #   Update the NextRestart value of a specific scheduled restart entry.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Update-KSScheduledRestart updates the LastRestart value and the hash for a specific entry in the schedule file.
  # .PARAMETER ComputerName
  # .PARAMETER LastRestart
  # .PARAMETER ScheduleFile
  # .INPUTS
  #   System.String
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     10/10/2014 - Chris Dent - BugFix: DateTime culture. Changed date time to a universal string format.
  #     08/10/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$ComputerName,
    
    [String]$NextRestart,
    
    [String]$ScheduleFile = "$(Get-KSSetting KSSchedules -ExpandValue)\ScheduledRestart.csv"
  )
  
  $Schedule = Import-Csv $ScheduleFile | ForEach-Object {
    if ($_.ComputerName -eq $ComputerName) {
      if ($psboundparameters.ContainsKey('NextRestart')) {
        $NextRestartDate = Get-Date $NextRestart
      } else {
        if (-not $_.NextRestart) {
          $NextRestartDate = Get-Date "$($_.HourOfDay):00:00"
          if ((Get-Date) -gt $NextRestartDate) {
            $NextRestartDate = $NextRestartDate.AddDays(1)
          }
        } else {
          # This is localised on read.
          $LastRestart = Get-Date $_.NextRestart
        
          $NextRestartDate = switch ($_.Frequency) {
            'Daily'   { $LastRestart.AddDays(1) }
            'Weekly'  { $LastRestart.AddDays(7) }
            'Monthly' { $LastRestart.AddMonths(1) }
          }
        }
      }

      $_.NextRestart = $NextRestartDate.ToString("yyyy-MM-dd HH:00:00")
      $_.RecordHash = Get-KSHash ($_ | Select-Object * -ExcludeProperty RecordHash | ConvertTo-Csv | Select-Object -Last 1) -Algorithm Sha1 -AsString
    }
    $_
  }
  
  $Schedule | Export-Csv $ScheduleFile -NoTypeInformation
}