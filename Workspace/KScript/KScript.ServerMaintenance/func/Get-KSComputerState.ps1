function Get-KSComputerState {
  # .SYNOPSIS
  #   Get the state of a specific computer.
  # .DESCRIPTION
  #   Get-KSComputerState attempts to ascertain the state of a computer using a number of different sources. These include:
  #
  #     * CMDB (\\uknasdata18\CORETECH\CMDB)
  #     * Active Directory
  #     * Network access (Ping, SSH, RPC, SMB)
  #
  # .PARAMETER ComputerName
  #   The name of the computer to search for.
  # .EXAMPLE
  #   Get-KSComputerState -ComputerName SomeComputer
  # .EXAMPLE
  #   Get-Content ServerList.txt | Get-KSComputerState
  # .EXAMPLE
  #   Import-KSExcelWorksheet Computers.xlsx -WorksheetName Retired | Get-KSComputerState
  #
  #   Note: The spreadsheet must contain a column named ComputerName or Name.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     06/01/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputerName
  )
  
  process {
    $ADObject = Get-KSADComputer -Name $ComputerName -SearchRoot (Get-KSADRootDSE | Select-Object -ExpandProperty rootDomainNamingContext) -UseGC
    
    New-Object PSObject -Property ([Ordered]@{
      ComputerName   = $ComputerName
      IPAddress      = ([Net.Dns]::GetHostEntry($ComputerName) | Select-Object -ExpandProperty AddressList)
      RespondsToPing = (Test-Connection $ComputerName -Quiet -Count 2)
      RespondsToRPC  = (try { 
      RespondsToSMB  = 
      RespondsToSSH  =
      
    })
  }
}