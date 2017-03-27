function Remove-KSADUserPhoto {
  # .SYNOPSIS
  #   Remove a photo from a user.
  # .DESCRIPTION
  #   Remove-KSADUserPhoto clears the thumbnailPhoto property for a user from Active Directory.
  # .PARAMETER Force
  #   Suppress confirmation dialogue.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER KSADUser
  #   A user returned by Get-KSADUser. KSADUser will automatically fill from the pipeline.
  # .INPUTS
  #   KScript.AD.User
  #   System.String
  # .EXAMPLE
  #   Get-KSADUser "AUser" | Remove-KSADUserPhoto
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/10/2014 - Chris Dent - BugFix: ShouldContinue arguments.
  #     03/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByIdentity')]
  param(
    [Parameter(Position = 1, ParameterSetName = 'ByIdentity')]
    [ValidateNotNullOrEmpty()]
    [String]$Identity,
    
    [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.AD.User' } )]
    $KSADUser,
    
    [Switch]$Force
  )

  begin {
    if ($pscmdlet.ParameterSetName -eq 'ByIdentity') {
      Get-KSADUser -Identity $Identity | Set-KSADUserPhoto -FileName $FileName
    }
  }
  
  process {
    if ($KSADUser) {
      if ($pscmdlet.ShouldProcess("$($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
        if ($KSADUser.ThumbnailPhoto) {
          if ($Force -or $pscmdLet.ShouldContinue("Remove photo from $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))?", "")) {
            $DirectoryEntry = $KSADUser.GetDirectoryEntry()
            $DirectoryEntry.Properties['thumbnailPhoto'].Clear()
            try {
              $DirectoryEntry.SetInfo()
            } catch [UnauthorisedAccessException] {
              Write-Error "Access denied while setting thumbnailPhoto for $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))" -Category PermissionDenied
            } catch {
              Write-Error $_.Exception.Message.Trim() -Category OperationStopped
            }
          }
        } else {
          Write-Verbose "Remove-KSADUserPhoto: thumbnailPhoto is not set."
        }
      }
    }
  }
}