function Set-KSLyncLineURI {
  # .SYNOPSIS
  #   Set RemoteCallControlTelephonyEnabled, LineURI and LineServerURI values for Lync enabled users.
  # .DESCRIPTION
  #   Set-KSLyncLineURI attempts to set RemoteCallControlTelephonyEnabled, LineURI and LineServerURI for Lync enabled users.
  # 
  #   If the user does not exist, or is not Lync enabled an error will be returned.
  #
  #   If the user account is explicitly denied RemoteCallControlTelephonyEnabled in policy (see Get-KSLyncUserPolicy) no changes will be made.
  # .PARAMETER UserPrincipalName
  #   
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/08/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidatePattern('^[^@]+@kpmg\.com$')]
    [String]$UserPrincipalName,
    
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$IPPhone
  )
  
  begin {
    if ($pscmdlet.ShouldProcess("Importing Lync management session.")) {
      Import-KSLyncSession
      if (-not $?) {
        break
      }
    } else {
      if (-not (Get-Command Get-CsAdUser)) {
        Write-KSLog "Get-CsAdUser command not found; Lync module not loaded." -LogLevel Warning
        break
      }
    }
  }
  
  process {
    $CsAdUser = Get-CsAdUser -Identity $UserPrincipalName
    if ($CsAdUser -and $CsAdUser.Enabled) {
    
      # LineServerURI and LineURI values can only be set if policy allows the user to have RemoteCallControlTelephonyEnabled.
    
      $RCCAllowed = $true
      Test-KSLyncUserPolicy -UserPrincipalName $UserPrincipalName | ForEach-Object {
        if ($_.Commands -match 'RemoteCallControlTelephonyEnabled \$false') {
          $RCCAllowed = $false
        }
      }
      
      if ($RCCAllowed) {
        Write-KSLog "  Setting LineURI and LineServerURI."
      
        $CSUser = Get-CsUser -Identity $UserPrincipalName

        $Error.Clear()
        if ($CsUser) {
          $CsUser | Set-CsUser -RemoteCallControlTelephonyEnabled $true `
            -LineServerURI "sip:$($CsUser.SamAccountName)@UKNLBCUP001.uk.kworld.kpmg.com" `
            -LineURI "tel:$IPPhone`;phone-context=dialstring"
        }
      } else {
        Write-KSLog "  LineURI and LineServerURI setting skipped, excluded by policy."
      }
      if ($Error) {
        $Error | ForEach-Object {
          Write-KSLog "  Set-KSLyncLineURI: $($_.Exception.Message.Trim())" -LogLevel Error
        }
      }
    } else {
      Write-Error "$UserPrincipalName not found or not Lync enabled"
    }
  }
}