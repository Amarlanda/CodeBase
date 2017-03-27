function Disable-KSLyncUser {
  # .SYNOPSIS
  #   Disable Lync user accounts with Disable-CsUser.
  # .DESCRIPTION
  #   Disable-KSLyncUser finds LyncUsers using the UserPrincipalName (which is an acceptable identity for Get-CsUser). The resulting CSUser is passed to Disable-CsUser to completely remove a Lync account.
  #
  #   Remove-LyncUser is reliant on a connection to the LyncManagementURI setting published using Get/Set-KSSetting.
  #
  #   All actions taken by this script are logged using Write-KSLog.
  # .PARAMETER LdapFilter
  #   Disable-KSLyncUser finds disabled AD accounts which are enabled in the Lync system by default. An alternative filter may be specified here.
  # .PARAMETER PassThru
  #   Send the user account from Get-CsAdUser to the output pipeline.
  # .PARAMETER SearchRoot
  #   The starting point for the Active Directory search. SearchRoot is mandatory as Get-CsAdUser performs a forest-wide search without this.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Disable-KSLyncUser
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     29/07/2014 - Chris Dent - Removed ErrorVariable from Disable-CsUser (not permitted).
  #     24/07/2014 - Chris Dent - Algorithm changed to resemble Enabled-KSLyncUser.
  #     17/07/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$LdapFilter = "(&(userAccountControl:1.2.840.113556.1.4.803:=2)(msRTCSIP-UserEnabled=TRUE))",
  
    [ValidateNotNullOrEmpty()]
    [String[]]$SearchRoot = @("ou=Disabled Accounts,dc=uk,dc=kworld,dc=kpmg,dc=com", "ou=Function,dc=uk,dc=kworld,dc=kpmg,dc=com", "ou=Privileged Accounts,dc=uk,dc=kworld,dc=kpmg,dc=com"),
    
    [Switch]$PassThru
  )

  Write-KSLog "Started $($myinvocation.InvocationName)"
  
  if ($psboundparameters.ContainsKey("WhatIf")) {
    Write-KSLog "WhatIf is set, no changes will be made."
  }
  
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
  
  $SearchRoot | ForEach-Object {
 
    Write-KSLog "Starting AD query"
    Write-KSLog "  Using LdapFilter $LdapFilter"
    Write-KSLog "  Using $_"
    
    Get-CsAdUser -LDAPFilter $LdapFilter -OU $_ | ForEach-Object {
    
      Write-KSLog "User: $($_.UserPrincipalName)"
      Write-KSLog "  Description:   $($_.Description)"
      Write-KSLog "  UAC:           $($_.UserAccountControl)"
      Write-KSLog "  SIPAddress:    $($_.SipAddress)"

      try {
        if ($pscmdlet.ShouldProcess("Disabling Lync user $($_.Identity)")) {
          $Error.Clear()
          Disable-CsUser -Identity $_.Identity
          if ($Error) {
            Write-KSLog "  Disable-CsUser: $($Error[0].Exception.Message)" -LogLevel Error
          }
        }
      } catch {
        Write-KSLog "  Disable-CsUser: $($_.Exception.Message)" -LogLevel Error
      }
      
      if ($PassThru) {
        $_
      }
    }
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)"
}