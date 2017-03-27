function Remove-KSScheduledRestart {
  # .SYNOPSIS
  #   Remove an existing scheduled restart.
  # .DESCRIPTION
  #   Removes a scheduled restart entry from the schedule file.
  # .PARAMETER ComputerName
  #   The ComputerName to remove from the schedule file. Wildcards are supported.
  # .PARAMETER ScheduleFile
  #   The location and file name of the schedule file. By default the file is stored in the path advertised by the KSSchedules setting (see Get-KSSetting).
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Remove-KSScheduledRestart -ComputerName SomeComputer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     14/10/2014 - Chris Dent - BugFix: Cannot read and change CSV in the same pipeline.
  #     08/10/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory = $true)]
    [String]$ComputerName,
  
    [String]$ScheduleFile = "$(Get-KSSetting KSSchedules -ExpandValue)\ScheduledRestart.csv"
  )
  
  if (Test-Path $ScheduleFile -PathType Leaf) {
    $RecordsToRemove = Get-KSScheduledRestart $ComputerName
    if ($RecordsToRemove) {
      $RecordsToRemove | ForEach-Object {
        if ($pscmdlet.ShouldProcess("Removing $($_.ComputerName)")) {
          $ComputerName = $_.ComputerName
          $ScheduledRestart = Import-Csv $ScheduleFile |
            Where-Object { $_.ComputerName -ne $ComputerName }
          $ScheduledRestart | Export-Csv $ScheduleFile -NoTypeInformation
        }
      }
    } else {
      Write-Warning "$ComputerName was not found in the schedule file."
    }
  } else {
    Write-Warning "$ScheduleFile does not exist."
  }
}