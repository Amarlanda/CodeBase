function Compress-KSItem {
  # .SYNOPSIS
  #   Compress a file or directory.
  # .DESCRIPTION
  #   Create a zip file from a collection of files.
  # .PARAMETER ArchiveName
  #   The name of the zip archive to create. If a name is not specified the first item in the input pipeline will be used to name the archive. If CreateFromDirectory is used the zip archive will be named after the directory.
  # .PARAMETER Clobber
  #   Remove and replace any existing zip file of the same name.
  # .PARAMETER CompresionLevel
  #   By default the compression level is set to Optimal. Alternatives are Fastest or NoCompression.
  # .PARAMETER CreateFromDirectory
  #   A zip file can be created from a directory without using Get-ChildItem. A directory name should be specified for ItemName along with this parameter.
  #
  #   If a zip file already exists using specified name it will be overwritten.
  # .PARAMETER ItemName
  #   The name of the item to compress.
  # .PARAMETER PreserveDirectoryStructure
  #   Compress-KSItem attempts to preserve the directory structure when creating a zip file. This behaviour may be disabled by setting PreserveDirectoryStructure to false.
  # .INPUTS
  #   System.Boolean
  #   System.IO.Compression.CompressionLevel
  #   System.String
  # .EXAMPLE
  #   Compress-KSItem .\SomeFile.txt
  #
  #   Compress the SomeFile.txt file and add it to the archive SomeFile.zip.
  # .EXAMPLE
  #   Compress-KSItem C:\SomeDirectory -CreateFromDirectory
  # 
  #   Create an archive called SomeDirectory.zip from the folder SomeDirectory.
  # .EXAMPLE
  #   Get-ChildItem C:\SomeDirectory -Filter *.doc -Recurse | Compress-KSItem
  # 
  #   Create an archive of doc files found using Get-ChildItem. Paths relative to the starting-point will be preserved in the zip archive.
  # .EXAMPLE
  #   Get-ChildItem C:\SomeDirectory -Filter *.xml -Recurse -PreserveDirectoryStructure $false
  #
  #   Create an archive of xml files found using Get-ChildItem. Paths will be flattened.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     14/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'CreateFromList')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'CreateFromList')]
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'CreateFromDirectory')]
    [ValidateScript( { Test-Path $_ } )]
    [Alias('FullName')]
    [String]$ItemName,
    
    [ValidatePattern('\.zip$')]
    [String]$ArchiveName,
   
    [IO.Compression.CompressionLevel]$CompressionLevel = [IO.Compression.CompressionLevel]::Optimal,
    
    [Parameter(ParameterSetName = 'CreateFromDirectory')]
    [Switch]$CreateFromDirectory,

    [Parameter(ParameterSetName = 'CreateFromList')]
    [Boolean]$PreserveDirectoryStucture = $true,

    [Parameter(ParameterSetName = 'CreateFromList')]
    [Switch]$Clobber
  )
  
  begin {
    if ($ArchiveName) {
      if (Test-Path $ArchiveName) {
        $ArchiveName = (Get-Item $ArchiveName).FullName
      } else {
        $ParentDirectory = Split-Path $ArchiveName
        
        if ($ParentDirectory) {
          if (Test-Path $ParentDirectory) {
            $ParentDirectory = (Get-Item $ParentDirectory).FullName
          } else {
            $ParentDirectory = (New-Item $ParentDirectory -PathType Directory -ErrorAction SilentlyContinue).FullName
            if (-not $?) {
              $ErrorRecord = New-Object Management.Automation.ErrorRecord(
                (New-Object ArgumentException "Unable to create directory for $ArchiveName ($ParentDirectory)."),
                "ArgumentException",
                [Management.Automation.ErrorCategory]::InvalidArgument,
                $ParentDirectory)
              $pscmdlet.ThrowTerminatingError($ErrorRecord)
            }
          }
        } else {
          $ParentDirectory = $pwd.Path
        }
        $ArchiveName = Join-Path $ParentDirectory (Split-Path $ArchiveName -Leaf)
      }
    }
  
    if ($Clobber -and (Test-Path $ArchiveName)) {
      Remove-Item $ArchiveName
    }
    
    if ($pscmdlet.ParameterSetName -eq 'CreateFromDirectory') {
      $Item = Get-Item $ItemName
      
      if (-not $ArchiveName) {
        $ArchiveName = Join-Path $pwd.Path "$($Item.BaseName).zip"
        if (Test-Path $ArchiveName) {
          Remove-Item $ArchiveName
        }
      }

      if ($Item -is [IO.DirectoryInfo]) {
        if ((Split-Path $ArchiveName) -like "$($Item.FullName)*") {
          Write-Error "Zip file ($ArchiveName) cannot be created within the directory being archived ($($Item.FullName))." -Category InvalidArgument
        } else {
          Write-Verbose "Compress-KSItem: Adding $($Item.FullName) to $ArchiveName"
        
          [IO.Compression.ZipFile]::CreateFromDirectory(
            $Item.FullName,
            $ArchiveName,
            $CompressionLevel,
            $true
          )
        }
      } else {
        Write-Error "Item must be a directory to use CreateFromDirectory." -Category InvalidArgument
      }
    }
  }
  
  process {
    if ($pscmdlet.ParameterSetName -eq 'CreateFromList' -and (Test-Path $ItemName)) {
      $Item = Get-Item $ItemName
    
      if (-not $ArchiveName) {
        $ArchiveName = Join-Path $pwd.Path "$($Item.BaseName).zip"
        if ($Clobber -and (Test-Path $ArchiveName)) {
          Remove-Item $ArchiveName
        }
      }

      if (-not $EntryBase -and $PreserveDirectoryStucture) {
        $EntryBase = switch ($Item.GetType()) {
          ([IO.DirectoryInfo]) { $Item.Parent.FullName }
          ([IO.FileInfo])      { $Item.DirectoryName }
        }
      }
      
      if ($Item -is [IO.FileInfo]) {
        Write-Verbose "Compress-KSItem: Adding $($Item.FullName) to $ArchiveName"

        if (Test-Path $ArchiveName) {
          $Stream = New-Object IO.FileStream($ArchiveName, [IO.FileMode]::Open)
          $ZipArchive = New-Object IO.Compression.ZipArchive($Stream, "Update")
        } else {
          $ZipArchive = [IO.Compression.ZipFile]::Open($ArchiveName, "Create")
        }

        if ($PreserveDirectoryStucture) {
          $EntryName = $Item.FullName.Replace("$EntryBase\", "")
        } else {
          $EntryName = $Item.Name
        }
        
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
          $ZipArchive,
          $Item.FullName,
          $EntryName,
          $CompressionLevel
        ) | Out-Null
        
        $ZipArchive.Dispose()
      } else {
        Write-Verbose "Compress-KSItem: Skipping DirectoryInfo: $($Item.FullName)"
      }
    }
  }
}