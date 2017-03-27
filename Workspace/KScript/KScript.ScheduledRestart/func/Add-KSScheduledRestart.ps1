function Add-KSScheduledRestart {
  # .SYNOPSIS
  #   Add a scheduled restart to the schedule file.
  # .DESCRIPTION
  #   Add a scheduled restart to the schedule file.
  # .PARAMETER Comment
  #   A comment indicating why the server is listed (if possible).
  # .PARAMETER ComputerName
  #   The name of the computer to restart.
  # .PARAMETER Frequency
  #   How often the system should be rebooted. Daily, Weekly or Monthly.
  # .PARAMETER HourOfDay
  #   The schedule operator runs once an hour. The HourOfDay and frequency are compared with the last restart time to determine whether or not a server may be restarted.
  # .PARAMETER Order
  #   The order (ascending) in which the service should be restarted. If an order is defined, servers will be rebooted in sequence.
  #
  #   Ordering is treated as dependency. If a server earlier in the list does not return to service subsequent reboot events will not be processed.
  # .PARAMETER ScheduleFile
  #   The location and file name of the schedule file. By default the file is stored in the path advertised by the KSSchedules setting (see Get-KSSetting).
  # .PARAMETER Service
  #   The name of the business service running on the computer. The service field is used to configure ordered restart processes.
  # .PARAMETER ServiceProbe
  #   A service probe is used to determine whether or not the server has returned to service.
  #
  #   By default, the script will attempt to use ICMP (ping), however the script may also be configured to poll a TCP port by number. UDP ports cannot be polled.
  # .INPUTS
  #   System.Byte
  #   System.String
  # .OUTPUTS
  #   KScript.KSScheduledRestart
  # .EXAMPLE
  #   Add-KSScheduledRestart -ComputerName SomeComputer -Service "SomeService" -Comment "Forceful service restart. INC12346789." -Frequency Daily -HourOfDay 6
  #
  #   Adds a scheduled restart for SomeComputer.
  # .EXAMPLE
  #   Add-KSScheduledRestart -ComputerName SomeComputer -Service "SomeService" -ServiceProbe 135 -Frequency Daily -HourOfDay 14
  #
  #   Configure a service to restart at 2PM every day. Use TCP/135 (the RPC end-point mapper) to determine if the server has returned to service.
  # .EXAMPLE
  #   Add-KSScheduledRestart -ComputerName SomeComputer -Service "SomeService" -ServiceProbe 80 -Frequency Weekly -HourOfDay 12 -FirstRestart "13/10/2014"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     08/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputerName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Service,
    
    [String]$Comment,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet('Daily', 'Weekly', 'Monthly')]
    [String]$Frequency,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateRange(0, 23)]
    [Byte]$HourOfDay,
    
    [ValidateNotNullOrEmpty()]
    [Byte]$Order = 1,
    
    [ValidatePattern('^(ICMP|\d{5})$')]
    [String]$ServiceProbe = "ICMP",
    
    [DateTime]$FirstRestart,
    
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$ScheduleFile = "$(Get-KSSetting KSSchedules -ExpandValue)\ScheduledRestart.csv"
  )
 
  if (Get-KSScheduledRestart -ComputerName $ComputerName -WarningAction SilentlyContinue) {
    Remove-KSScheduledRestart -ComputerName $ComputerName
  }

  $HourOfDayString = ([String]$HourOfDay).PadLeft(2, '0')
  
  $ScheduledRestart = New-Object PSObject -Property ([Ordered]@{
    ComputerName = $ComputerName
    Service      = $Service
    ServiceProbe = "ICMP"
    Order        = $Order
    Comment      = $Comment
    AddedBy      = $env:Username
    Frequency    = $Frequency
    HourOfDay    = $HourOfDayString
    NextRestart  = ""
    RecordHash   = $null
  })
  $ScheduledRestart.RecordHash = Get-KSHash ($ScheduledRestart | Select-Object * -ExcludeProperty RecordHash | ConvertTo-Csv | Select-Object -Last 1) -Algorithm Sha1 -AsString

  $ScheduledRestart | Export-Csv $ScheduleFile -NoTypeInformation -Append

  # Update the next scheduled restart date.
  $Params = @{}
  if ($psboundparameters.ContainsKey("FirstRestart")) {
    $Params.Add("NextRestart", (Get-Date "$HourOfDay:00:00 $($FirstRestart.ToString('dd/MM/yyyy'))"))
  }
  Update-KSScheduledRestart -ComputerName $ScheduledRestart.ComputerName @Params
  
  if ($PassThru) {
    Get-KSScheduledRestart $ComputerName
  }
}