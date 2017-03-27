function Show-KSADUserPhoto {
  # .SYNOPSIS
  #   Show the photo associated with a user.
  # .DESCRIPTION
  #   Show-KSADUserPhoto gets the thumbnailPhoto property for a user from Active Directory then displays the image.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER KSADUser
  #   A user returned by Get-KSADUser. KSADUser will automatically fill from the pipeline.
  # .INPUTS
  #   KScript.AD.User
  #   System.String
  # .EXAMPLE
  #   Get-KSADUser "AUser" | Show-KSADUserPhoto
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'ByIdentity')]
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
      Get-KSADUser -Identity $Identity -Properties DisplayName, Name, ThumbnailPhoto | Show-KSADUserPhoto
    }
  }
  
  process {
    if ($KSADUser) {
      if ($KSADUser.ThumbnailPhoto) {
        $ByteStream = New-Object IO.MemoryStream(,[Byte[]]$KSADUser.ThumbnailPhoto)
        $BitMapImage = New-Object Drawing.Bitmap($ByteStream)

        $Form =  New-Object Windows.Forms.Form
        $Form.AutoSize = $true
        $Form.Size.Width = 150
        $Form.Size.Height = 150
        $Form.FormBorderStyle = "FixedDialog"
        $Form.MaximizeBox = $false
        $Form.MinimizeBox = $false
        
        $Form.Add_KeyDown( { if ($_.KeyCode -eq "Escape") { $Form.Close() } } )
        
        $Form.BackgroundImage = $BitMapImage
        $Form.BackgroundImageLayout = "Center"
        
        $Form.ShowDialog() | Out-Null
      } else {
        Write-Warning "Show-KSADUserPhoto: ThumbnailPhoto is not set for $($KSADUser.SamAccountName) ($($KSADUser.DistinguishedName))"
      }
    }
  }
}