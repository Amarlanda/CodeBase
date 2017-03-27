function Get-KSScheduledTask {
  # .SYNOPSIS
  #   Get scheduled tasks.
  # .DESCRIPTION
  #   Get scheduled tasks from the local or a remote system using the Schedule.Service COM Object.
  #
  #   Get-KSScheduledTask does not display triggers.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.ScheduledTask
  # .EXAMPLE
  #   Get-KSScheduledTask -ComputerName SomeComputer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     11/11/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$ComputerName = $env:ComputerName
  )
  
  $OperatingSystem = Get-WmiObject Win32_OperatingSystem -Property Caption -ComputerName $ComputerName
  
  $Scheduler = New-Object -COMObject Schedule.Service
  $Scheduler.Connect($ComputerName)

  switch -regex ($OperatingSystem.Caption) {
    'Server 2012' { $TaskFolder = $Scheduler.GetFolder("\KPMG"); break }
    default       { $TaskFolder = $Scheduler.GetFolder("\") }
  }
  
  $TaskFolder.GetTasks(0) | 
    ForEach-Object {
      $TaskXml = ([XML]$_.Xml).Task
    
      $_ |
        Select-Object Name, LastRunTime, NextRunTime, 
          @{n='State';e={
            switch ($_.State) {
              0 { "Unknown"; break }
              1 { "Disabled"; break }
              2 { "Queued"; break }
              3 { "Ready"; break }
              4 { "Running"; break }
            }
          }},
          @{n='Enabled';e={ (Get-Variable $TaskXml.Settings.Enabled).Value }},
          @{n='LastTaskResult';e={
            switch ($_.LastTaskResult) {
              0x0     { "The operation completed successfully"; break }
              0x41301 { "The task is currently running."; break }
              default { "Unknown state: $($_.LastTaskResult)" }
            }
          }},
          @{n='Command';e={
            if ($TaskXml.Actions.Exec.Command) {
              if ($TaskXml.Actions.Exec.Arguments) {
                "$($TaskXml.Actions.Exec.Command) $($TaskXml.Actions.Exec.Arguments)"
              } else {
                $TaskXml.Actions.Exec.Command
              }
            }
          }},
          @{n='UserID';e={ $TaskXml.Principals.Principal.UserId }},
          @{n='RunLevel';e={ $TaskXml.Principals.Principal.RunLevel }} |
        ForEach-Object {
          $_.PSObject.TypeNames.Add("KScript.CMDB.ScheduledTask")
          
          $_
        }
    }
}