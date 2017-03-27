function Test-KSESXCredential {
  # .SYNOPSIS
  #   Test a set of credentials against an ESX server.
  # .DESCRIPTION
  #
  # .PARAMETER ComputerName
  #   A ComputerName to perform the test against.
  # .PARAMETER Password
  #   A single password, or list of passwords, to attempt.
  # .PARAMETER Username
  #   The username to test, by default the root user is used.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$ComputerName,
    
    [String]$Username = "root",
    
    [Parameter(Mandatory = $true)]
    [String[]]$Password
  )
  
  process {
    $Password | ForEach-Object {
      Connect-VIServer $ComputerName -User root -Password $_ -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
      if ($?) {
        Disconnect-VIServer $ComputerName
        return $_
      }
    }
  }
}