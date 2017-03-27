function Get-KSNetStat {
  # .SYNOPSIS
  #   Get network statistics.
  # .DESCRIPTION
  #   Get-KSNetStat executes netstat on a remote computer, redirecting the output to a text file. The file content is read and returned as an object.
  #
  #   Get-KSNetStat requires administrative access to the remote host.
  # .PARAMETER ComputerName
  #   The computer name to execute against.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.NetworkStatistic
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     17/10/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    $ComputerName = $env:ComputerName
  )
  
  if ($ComputerName -eq $env:ComputerName) {
    $TempPath = "c:\Windows\Temp"
  } else {
    $TempPath = "\\$ComputerName\c$\Windows\Temp"
  }
  
  if (Test-Path $TempPath -ErrorAction Stop) {
    $Command = "cmd.exe /c netstat -abno > $TempPath\netstat.txt"
    $Process = Invoke-WmiMethod -Name Create -Class Win32_Process -ArgumentList $Command -ComputerName $ComputerName

    if ($Process.ReturnValue -eq 0) {
      $i = 0
      while ((Get-WmiObject Win32_Process -Filter "ProcessID='$($Process.ProcessID)'" -ComputerName $ComputerName -ErrorAction SilentlyContinue) -or $i -lt 10) {
        Start-Sleep -Seconds 1
        $i++
      }
      
      if (Test-Path "$TempPath\netstat.txt") {
        $NetStat = Get-Content "$TempPath\netstat.txt"
        $Count = $NetStat.Count

        for ($i = 0; $i -lt $Count; $i++) {
          if ($NetStat[$i] -match '^\s*(?<Protocol>TCP|UDP)\s+(?<LocalAddress>\S+)\s+(?<ForeignAddress>\S+)(?:\s+(?<State>\S+))?\s+(?<ProcessID>\d+)') {
          
            $Component = $null; $Process = $null
          
            $NetworkStatistic = New-Object PSObject -Property ([Ordered]@{
              Protocol      = $matches.Protocol
              LocalAddress  = $matches.LocalAddress
              ForeignAddess = $matches.ForeignAddress
              State         = $matches.State
              ProcessID     = $matches.ProcessID
              Process       = $null
            })

            $IPAddress = [IPAddress]($NetworkStatistic.LocalAddress -replace ':\d+$')
            $Port = [UInt16]($NetworkStatistic.LocalAddress -replace '^.+:')
            $NetworkStatistic.LocalAddress = New-Object Net.IPEndPoint($IPAddress, $Port)

            if ($NetworkStatistic.ForeignAddress) {
              $IPAddress = [IPAddress]($NetworkStatistic.ForeignAddress -replace ':\d+$')
              $Port = [UInt16]($NetworkStatistic.ForeignAddress -replace '^.+:')
              $NetworkStatistic.ForeignAddress = New-Object Net.IPEndPoint($IPAddress, $Port)
            }
            
            if ($NetworkStatistic.State -ne 'TIME_WAIT') {
              if ($NetStat[++$i] -notmatch 'Can not obtain ownership information') {
                if ($NetStat[$i] -notmatch '^\s*\[') {
                  $Component = $NetStat[$i++].Trim()
                }
                $Process = ($NetStat[$i] -replace '[\[\]]').Trim()
                
                if ($Component) {
                  $NetworkStatistic.Process = "$Process ($Component)"
                } else {
                  $NetworkStatistic.Process = $Process
                }
              }
            }
            $NetworkStatistic
          }
        }
        
        Remove-Item "$TempPath\netstat.txt"
      }
    }
  }
}