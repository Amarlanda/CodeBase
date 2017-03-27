function Update-KSADTelephoneNumber {
  # .SYNOPSIS
  #   Update telephone numbers in Active Directory based on the content of the IPPhone attribute.
  # .DESCRIPTION
  #   Update-KSADTelephoneNumber attempts to check and update telephoneNumber, otherTelephone and the Lync Line URI (msRTCSIP-Line) in Active Directory.
  #
  #   A Lync session is imported and the Lync CmdLets are used to update the Line URI value.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/12/2014 - Chris Dent - Added Lync account enabled check. Added error handling for Set-CsUser.
  #     27/11/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param( )

  Write-KSLog "Starting $($myinvocation.InvocationName)" -StartTranscript

  if (-not $psboundparameters.ContainsKey("WhatIf") -and -not $LyncSessionImported) {
    Import-KSLyncSession
    if ($?) {
      $LyncSessionImported = $true
    } else {
      Write-KSLog "Failed to import Lync management session" -LogLevel Error
      $LyncSessionImported = $false
    }
  }

  Get-KSADUser -IPPhone * -Enabled -Properties Name, ipPhone, telephoneNumber, otherTelephone, userPrincipalName, msRTCSIP-Line, msRTCSIP-UserEnabled -SizeLimit 0 | ForEach-Object {
    $KSADUser = $_

    if ($KSADUser.ipPhone -match '^\d{8}$') {
      $SetParams = @{}
      $GeneratedNumbers = Get-KSTelephoneNumber -IPPhone $KSADUser.ipPhone
      $GeneratedNumbers.PSObject.Properties | Where-Object { $_.Name -match 'phone' -and $_.Value } | ForEach-Object {
        if ($KSADUser.$($_.Name) -ne $_.Value) {
          $SetParams.Add($_.Name, $_.Value)
        }
      }
      
      $LoggedUser = $false
      if (($SetParams.Keys | Measure-Object).Count -ge 1) {
        Write-KSLog "User: $($KSADUser.UserPrincipalName)"
        $LoggedUser = $true
        $SetParams.Keys | ForEach-Object {
          Write-KSLog "  Updating $_ from $($KSADUser.$_) to $($SetParams[$_])"
        }
      
        if ($psboundparameters.ContainsKey("WhatIf")) {
          $KSADUser | Set-KSADUser @SetParams -WhatIf
        } else {
          $KSADUser | Set-KSADUser @SetParams
        }
      }

      if ($KSADUser.'msRTCSIP-UserEnabled' -and $KSADUser.'msRTCSIP-Line' -and $KSADUser.'msRTCSIP-Line' -notmatch "^tel:$($KSADUser.ipPhone)") {
        if (-not $LoggedUser) {
          Write-KSLog "User: $($KSADUser.UserPrincipalName)"
        }
        Write-KSLog "  Updating Lync LineURI from $($KSADUser.'msRTCSIP-Line') to tel:$($KSADUser.ipPhone);phone-context=dialstring"

        if ($LyncSessionImported) {
          $CsUser = Get-CsUser -Identity $KSADUser.userPrincipalName
          if ($CsUser -and $CsUser.RemoteCallControlTelephonyEnabled) {
            try {
              $CsUser | Set-CsUser -LineURI "tel:$($KSADUser.ipPhone);phone-context=dialstring" -ErrorAction Stop
            } catch {
              Write-KSLog $_.Exception.Message.Trim() -LogLevel Error
            }
          }
        }
      }
    } else {
      Write-KSLog "User: $($KSADUser.UserPrincipalName)"
      Write-KSLog "  Unexpected IPPhone format - $($KSADUser.ipPhone)"
    }
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}