function Resize-KSImageFile {
  # .SYNOPSIS
  #   Resize image an image file.
  # .DESCRIPTION
  #   Resize an existing image file.
  # .PARAMETER FileName
  #   The name of the file to resize.
  # .PARAMETER Width
  #   The new width of the image.
  # .PARAMETER Height
  #   The new height of the image.
  # .PARAMETER PreserveAspectRatio
  #   Attempt to preserve the current aspect ratio. Pixel counts will be rounded if they are not a whole number.
  # .INPUTS
  #   System.String
  #   System.Int32
  # .EXAMPLE
  #   Resize-KSImageFile image.png -Width 200 -PreserveAspectRatio
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     27/06/2014 - Chris Dent - Modified to use temporary file: Saving the image to the same file it was constructed from is not allowed and throws an exception. (http://msdn.microsoft.com/en-us/library/ktx83wah.aspx)
  #     26/06/2014 - Chris Dent - Forked from original function (KPMG.KScript.Core\Set-KpmgImageFileSize). Only modifies image if size has changed.
  
  [CmdLetBinding(DefaultParameterSetName = 'WidthAndHeight')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName')]
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$FileName,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'WidthAndHeight')]
    [Parameter(Mandatory = $true, ParameterSetName = 'WidthAndPreserveAspectRatio')]
    [ValidateRange(1, 2147483647)]
    [Int32]$Width,

    [Parameter(Mandatory = $true, ParameterSetName = 'WidthAndHeight')]
    [Parameter(Mandatory = $true, ParameterSetName = 'HeightAndPreserveAspectRatio')]
    [ValidateRange(1, 2147483647)]
		[Int32]$Height,

    [Parameter(Mandatory = $true, ParameterSetName = 'WidthAndPreserveAspectRatio')]
    [Parameter(Mandatory = $true, ParameterSetName = 'HeightAndPreserveAspectRatio')]
    [Switch]$PreserveAspectRatio
  )
  
  process {
    $FileName = (Get-Item $FileName).FullName
    
    $TempFile = [IO.Path]::GetTempFileName()
    if ($TempFile) {
      Copy-Item $FileName $TempFile
      if ($?) {
        $Image = New-Object Drawing.Bitmap $TempFile

        if ($PreserveAspectRatio -and $Width) {
          $Ratio = $Image.Width / $Image.Height
          $Height = [Math]::Round(($Width * $Ratio))
        } elseif ($PreserveAspectRatio -and $Height) {
          $Ratio = $Image.Width / $Image.Height
          $Width = [Math]::Round(($Height * $Ratio))
        }
        
        if ($Image.Width -ne $Width -or $Image.Height -ne $Height) {
          $NewImage = New-Object Drawing.Bitmap $Width, $Height
          
          $Graphics = [Drawing.Graphics]::FromImage($NewImage)
          $Graphics.InterpolationMode = [Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
          $Graphics.DrawImage($Image, 0, 0, $Width, $Height)

          $NewImage.Save($FileName, $Image.RawFormat)
        } else {
          Write-Verbose "No changes to image."
        }
        $Image.Dispose()
      }
      Remove-Item $TempFile
    }
  }
}
