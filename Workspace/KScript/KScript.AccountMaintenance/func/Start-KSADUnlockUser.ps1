function Start-KSADUnlockUser {
  # .SYNOPSIS
  #   Start a perpetual account unlock job for all users in the specified file.
  # .DESCRIPTION
  #   This script is designed to work-around persistent account lockout problems, it is a last resort and should not replace investigation of the problem. The script loops through all users in a text file, checking and unlocking each every 60 seconds.
  #
  #   The Account Lockout mechanism is a security control designed to protect the domain (and individual user data) from attack. This script effectively disables that control and represents a significant security risk for the accounts it operates against.
  #
  #   The script operates against a formatted CSV file with the following header:
  #
  #     Username,ForceUnlock
  #
  #   The username must resolve to a unique principal within the current domain. The ForceUnlock option is present to allow behaviour monitoring of specific users, somewhat equivalent to a WhatIf mode for the script.
  # .PARAMETER FileName
  #   Start-KSADUnlockUser expects a single text file containing SamAccountName values (in the current domain) as input. Blank or empty values are ignored.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Start-KSADUnlockUser -FileName UserList.txt
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/12/2014 - Chris Dent - Added automatic log searcher option.
  #     22/09/2014 - Chris Dent - Modified to poll all DCs. Added verbose logging. Modified input file to CSV (to allow a diagnostic mode).
  #     18/09/2014 - Chris Dent - First release

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$FileName
  )
  
  Write-KSLog "Starting $($myinvocation.InvocationName)" -StartTranscript
  Write-KSLog "Writing unlock events with the header DisplayName|SamAccountName|WhenUnlocked|DCName"

  $DomainControllers = Get-KSADDomainController -Properties Name
  
  while ($true) {
    Import-Csv $FileName | ForEach-Object {
      $Entry = $_
      if ($Entry.ForceUnlock -match '^(true|false)$') {
        $ForceUnlock = (Get-Variable $Entry.ForceUnlock).Value
      } else {
        $ForceUnlock = $false
      }
      
      $DomainControllers | ForEach-Object {
        $DCName = $_.Name
      
        $KSADUser = Get-KSADUser -SamAccountName $Entry.UserName -Properties DisplayName, LockoutTime, SamAccountName -ComputerName $DCName
        
        Write-Verbose "$($KSADUser.DisplayName) - $($KSADUser.SamAccountName) @ $($DCName): Locked: $($KSADUser.AccountIsLockedOut)"
        
        if ($KSADUser.AccountIsLockedOut) {
          Write-Verbose "$($KSADUser.DisplayName) - $($KSADUser.SamAccountName) @ $($DCName): Unlocked"
          Write-KSLog "$($KSADUser.DisplayName)|$($KSADUser.SamAccountName)|$(Get-Date)|$DCName"

          if ($ForceUnlock) {
            $KSADUser | Unlock-KSADUser
          }
        }
      }
    }
    
    Start-Sleep -Seconds 60
  }
}