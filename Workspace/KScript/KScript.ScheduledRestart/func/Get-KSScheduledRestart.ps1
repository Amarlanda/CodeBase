function Get-KSScheduledRestart {
  # .SYNOPSIS
  #   Get scheduled restart operations.
  # .DESCRIPTION
  #   Get and validate the computers configured to restart on a schedule.
  # .PARAMETER ComputerName
  #   Filter results to a specific ComputerName in the schedule file. Wildcards are supported.
  # .PARAMETER ScheduleFile
  #   The location and file name of the schedule file. By default the file is stored in the path advertised by the KSSchedules setting (see Get-KSSetting).
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.KSScheduledRestart
  # .EXAMPLE
  #   Get-KSScheduledRestart
  #
  #   Get all computer names scheduled to restart.
  # .EXAMPLE
  #   Get-KSScheduledRestart -ComputerName SomeComputer
  #
  #   Get the scheduled restart details for the specified computer name.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     08/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$ComputerName = '*',
  
    [String]$ScheduleFile = "$(Get-KSSetting KSSchedules -ExpandValue)\ScheduledRestart.csv"
  )

  if (Test-Path $ScheduleFile -PathType Leaf) {
    Import-Csv $ScheduleFile | Where-Object { $_.ComputerName -like $ComputerName } | ForEach-Object {
      $ScheduledRestart = $_
    
      # Property: RecordIsValid
      $_ | Add-Member RecordIsValid -MemberType NoteProperty -Value $(
        $RecordHash = Get-KSHash ($ScheduledRestart | Select-Object * -ExcludeProperty RecordHash | ConvertTo-Csv | Select-Object -Last 1) -Algorithm Sha1 -AsString
        if ($RecordHash -eq $ScheduledRestart.RecordHash) {
          $true
        } else {
          $false
        }
      )
      $_.PSObject.TypeNames.Add("KScript.ScheduledRestart")
      
      $_
    }
  } else {
    Write-Warning "$ScheduleFile does not exist."
  }
}