function Enable-KSADUser {
  # .SYNOPSIS
  #   Enables a user account.
  # .DESCRIPTION
  #   Enable an Active Directory user account.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER KSADUser
  #   A user returned by Get-KSADUser. KSADUser will automatically fill from the pipeline.
  # .INPUTS
  #   KScript.AD.User
  #   System.String
  # .EXAMPLE
  #   Get-KSADUser "AUser" | Enable-KSADUser
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
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
      Get-KSADUser -Identity $Identity | Enable-KSADUser
    }
  }
  
  process {
    if ($KSADUser) {
      if ($pscmdlet.ShouldProcess("Enabling $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
        if ($KSADUser.AccountIsDisabled) {
          $DirectoryEntry = $KSADUser.GetDirectoryEntry()
          $DirectoryEntry.Properties['userAccountControl'] =
            $DirectoryEntry.Properties['userAccountControl'][0] -bxor [KScript.AD.UserAccountControl]::AccountDisable
          try {
            $DirectoryEntry.SetInfo()
          } catch [UnauthorisedAccessException] {
            Write-Error "Access denied while setting userAccountControl for $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))" -Category PermissionDenied
          } catch {
            Write-Error $_.Exception.Message.Trim() -Category OperationStopped
          }
        } else {
          Write-Verbose "Enable-KSADUser: Account is already enabled."
        }
      }
    }
  }
}