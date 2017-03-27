function Add-KSADUserPhoto {
  # .SYNOPSIS
  #   Add a photo to a user.
  # .DESCRIPTION
  #   Add-KSADUserPhoto adds a photo from a file to the thumbnailPhoto property for a user from Active Directory.
  # .PARAMETER FileName
  #   The photo file to add. The photo will be resized to 72 by 72 pixels.
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
  #   Get-KSADUser "AUser" | Add-KSADUserPhoto -FileName "Photo.jpg"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/10/2014 - Chris Dent - BugFix: ShouldContinue arguments.
  #     13/10/2014 - Chris Dent - BugFix: Exception name (US spelling).
  #     03/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByIdentity')]
  param(
    [Parameter(Position = 1, ParameterSetName = 'ByIdentity')]
    [ValidateNotNullOrEmpty()]
    [String]$Identity,
    
    [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.AD.User' } )]
    $KSADUser,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$FileName,
    
    [Switch]$Force
  )

  begin {
    if ($pscmdlet.ParameterSetName -eq 'ByIdentity') {
      Get-KSADUser -Identity $Identity | Set-KSADUserPhoto -FileName $FileName
    }
  }
  
  process {
    if ($KSADUser) {
      if ($pscmdlet.ShouldProcess("$FileName adding to $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
        Resize-KSImageFile $FileName -Height 72 -Width 72
      
        $ThumbnailPhotoHash = $null
        if ($KSADUser.ThumbnailPhoto) {
          $ThumbnailPhotoHash = Get-KSHash -ByteArray $KSADUser.ThumbnailPhoto -Algorithm SHA1
        }
      
        if ($ThumbnailPhotoHash -eq (Get-KSHash -FileName $FileName)) {
          Write-Verbose "Set-KSADUserPhoto: $($KSADUser.SamAccountName) ($($KSADUser.ObjectGUID)): thumbnailPhoto is identical to $FileName"
        } else {
          $ThumbnailPhotoBytes = Get-Content $FileName -Encoding Byte -Raw
      
          if (-not $KSADUser.ThumbnailPhoto -or $Force -or $pscmdLet.ShouldContinue("Overwrite existing photo for  $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))?", "")) {
            $DirectoryEntry = $KSADUser.GetDirectoryEntry()
            $DirectoryEntry.Properties['thumbnailPhoto'].Clear()
            $DirectoryEntry.Properties['thumbnailPhoto'].Add($ThumbnailPhotoBytes) | Out-Null
            try {
              $DirectoryEntry.SetInfo()
            } catch [UnauthorizedAccessException] {
              Write-Error "Access denied while setting thumbnailPhoto for $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))" -Category PermissionDenied
            } catch {
              Write-Error $_.Exception.Message.Trim() -Category OperationStopped
            }
          }
        }
      }
    }
  }
}