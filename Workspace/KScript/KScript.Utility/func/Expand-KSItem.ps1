function Expand-KSItem {
  # .SYNOPSIS
  #   Expand the content of a zip file.
  # .DESCRIPTION
  #   Expand the content of a zip file to the specified directory.
  # .PARAMETER ArchiveName
  #   The name and path of the archive to extract.
  # .PARAMETER Destination
  #   The name of the folder to extract the zip file content to. Destination is the current working directory by default.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Expand-KSItem C:\Temp\SomeArchive.zip
  # .EXAMPLE
  #   Expand-KSItem C:\Temp\SomeArchive.zip -Destination C:\SomeArchive"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     14/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript( { Test-Path $_ -Filter *.zip -PathType Leaf } )]
    [String]$ArchiveName,
    
    [String]$Destination = $pwd.Path
  )
  
  process {
    if (Test-Path $Destination) {
      $Destination = (Get-Item $Destination).FullName
    } else {
      $Destination = (New-Item $Destination -Type Directory).FullName
    }
  
    $ArchiveName = (Get-Item $ArchiveName).FullName
    
    $Stream = New-Object IO.FileStream($ArchiveName, [IO.FileMode]::Open)
    $ZipArchive = New-Object IO.Compression.ZipArchive($Stream, "Read")
  
    [IO.Compression.ZipFileExtensions]::ExtractToDirectory($ZipArchive, $Destination)
    
    $ZipArchive.Dispose()
  }
}