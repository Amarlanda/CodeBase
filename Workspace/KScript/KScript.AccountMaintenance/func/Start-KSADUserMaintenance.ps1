function Start-KSADUserMaintenance {
  # .SYNOPSIS
  #   Start AD user maintenance tasks.
  # .DESCRIPTION
  #   Start-KSADUserMaintenance executes the following scripts in the order described:
  #
  #     * Clears IPPhone and TelephoneNumber.
  #
  #   Parameters set using this function (such as WhatIf and Verbose) are passed through to any called functions (such as Set-KSADUser).
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/08/2014 - Chris Dent - Added transcript logging option.
  #     04/08/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param( )
  
  Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript
  
  #
  # Telephony
  #
  
  Write-KSLog "Clearing IPPhone and TelephoneNumber for disabled users"

  Get-KSADUser -Disabled -LdapFilter "(|(ipPhone=*)(telephoneNumber=*)(otherTelephone=*))" -SizeLimit 0 | ForEach-Object {
    Write-KSLog "User: $($_.UserPrincipalName)"
    Write-KSLog "  Description:     $($_.Description)"
    Write-KSLog "  DN:              $($_.DistinguishedName)"
    Write-KSLog "  UAC:             $($_.UserAccountControl)"
    Write-KSLog "  IPPhone:         $($_.IPPhone)"
    Write-KSLog "  OtherTelephone:  $($_.OtherTelephone)"
    Write-KSLog "  TelephoneNumber: $($_.TelephoneNumber)"
    
    $_ | Set-KSADUser -IPPhone $null -OtherTelephone $null -TelephoneNumber $null @psboundparameters -ErrorVariable KSADUserError -ErrorAction SilentlyContinue
    if (-not $? -and $KSADUserError) {
      Write-KSLog "  Error: $($KSADUserError.Exception.Message.Trim())" -LogLevel Error
    }
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}