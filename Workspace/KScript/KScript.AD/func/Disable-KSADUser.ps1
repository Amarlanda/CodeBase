function Disable-KSADUser {
  # .SYNOPSIS
  #   Disable a user account.
  # .DESCRIPTION
  #   Disable an Active Directory user account.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER KSADUser
  #   A user returned by Get-KSADUser. KSADUser will automatically fill from the pipeline.
  # .INPUTS
  #   KScript.AD.User
  #   System.String
  # .EXAMPLE
  #   Get-KSADUser "AUser" | Disable-KSADUser
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     09/10/2014 - Chris Dent - BugFix: Typo in property name. Typo in exception type.
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
      Get-KSADUser -Identity $Identity | Disable-KSADUser
    }
  }
  
  process {
    if ($KSADUser) {
      if ($pscmdlet.ShouldProcess("Disabling $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
        if (-not ($KSADUser.AccountIsDisabled)) {
          $DirectoryEntry = $KSADUser.GetDirectoryEntry()
          $DirectoryEntry.Properties['userAccountControl'].Value = [Int]([UInt32]$DirectoryEntry.Properties['userAccountControl'].Value -bxor [KScript.AD.UserAccountControl]::AccountDisable)
          try {
            $DirectoryEntry.SetInfo()
          } catch [UnauthorizedAccessException] {
            Write-Error "Access denied while setting userAccountControl for $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))" -Category PermissionDenied
          } catch {
            Write-Error $_.Exception.Message.Trim() -Category OperationStopped
          }
        } else {
          Write-Verbose "Disable-KSADUser: Account is already disabled."
        }
      }
    }
  }
}