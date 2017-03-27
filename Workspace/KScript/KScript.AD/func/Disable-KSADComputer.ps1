function Disable-KSADComputer {
  # .SYNOPSIS
  #   Disable a computer account.
  # .DESCRIPTION
  #   Disable an Active Directory computer account.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER KSADUser
  #   A computer returned by Get-KSADComputer. KSADComputer will automatically fill from the pipeline.
  # .INPUTS
  #   KScript.AD.Computer
  #   System.String
  # .EXAMPLE
  #   Get-KSADComputer "AComputer" | Disable-KSADComputer
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
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.AD.Computer' } )]
    $KSADComputer
  )
  
  begin {
    if ($pscmdlet.ParameterSetName -eq 'ByIdentity') {
      Get-KSADComputer -Identity $Identity | Disable-KSADComputer
    }
  }
  
  process {
    if ($KSADComputer) {
      if ($pscmdlet.ShouldProcess("Disabling $($KSADComputer.SamAccountName) ($($KSADUser.objectGUID))")) {
        if (-not ($KSADComputer.AccountIsDisabled)) {
          $DirectoryEntry = $KSADComputer.GetDirectoryEntry()
          $DirectoryEntry.Properties['userAccountControl'] =
            $DirectoryEntry.Properties['userAccountControl'][0] -bxor [KScript.AD.UserAccountControl]::AccountDisable
          try {
            $DirectoryEntry.SetInfo()
          } catch [UnauthorisedAccessException] {
            Write-Error "Access denied while setting userAccountControl for $($KSADComputer.SamAccountName) ($($KSADComputer.objectGUID))" -Category PermissionDenied
          } catch {
            Write-Error $_.Exception.Message.Trim() -Category OperationStopped
          }
        } else {
          Write-Verbose "Disable-KSADComputer: Account is already disabled."
        }
      }
    }
  }
}