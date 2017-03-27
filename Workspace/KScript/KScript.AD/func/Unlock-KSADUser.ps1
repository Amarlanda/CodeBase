function Unlock-KSADUser {
  # .SYNOPSIS
  #   Unlock a user account.
  # .DESCRIPTION
  #   Unlock an Active Directory user account.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER KSADUser
  #   A user returned by Get-KSADUser. KSADUser will automatically fill from the pipeline.
  # .INPUTS
  #   KScript.AD.User
  #   System.String
  # .EXAMPLE
  #   Get-KSADUser "AUser" | Unlock-KSADUser
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     18/12/2014 - Chris Dent - Converted to use System.DirectoryServices.AccountManagement.
  #     19/09/2014 - Chris Dent - BugFix: Unlock method.
  #     07/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByIdentity')]
  param(
    [Parameter(Position = 1, ParameterSetName = 'ByIdentity')]
    [ValidateNotNullOrEmpty()]
    [String]$Identity,
   
    [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.AD.User' } )]
    $KSADUser
  )
  
  begin {
    if ($pscmdlet.ParameterSetName -eq 'ByIdentity') {
      Get-KSADUser -Identity $Identity | Unlock-KSADUser
    }
  }
  
  process {
    if ($KSADUser) {
      if ($pscmdlet.ShouldProcess("Unlocking $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
        if ($KSADUser.AccountIsLockedOut) {
          $AccountManagementPrincipal = $KSADUser.GetAccountManagementPrincipal()
          try {
            $AccountManagementPrincipal.UnlockAccount()
          } catch [UnauthorizedAccessException] {
            Write-Error "Access denied unlocking $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))" -Category PermissionDenied
          } catch {
            Write-Error $_.Exception.Message.Trim() -Category OperationStopped
          }
        } else {
          Write-Verbose "Unlock-KSADUser: Account is already unlocked."
        }
      }
    }
  }
}