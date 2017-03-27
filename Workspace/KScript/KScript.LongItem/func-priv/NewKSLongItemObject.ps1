function NewKSLongItemObject {
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [KScript.LongItem+WIN32_FIND_DATA]$FindData,
    
    [Parameter(Mandatory = $true)]
    [String]$Name
  )

  $Item = New-Object PSObject -Property ([Ordered]@{
    Name              = $FindData.cFileName
    FullName          = "$Name\$($FindData.cFileName)"
    Length            = ([UInt64]$FindData.nFileSizeHigh -shl 32) + [UInt64]$FindData.nFileSizeLow
    CreationTimeUtc   = [DateTime]::FromFileTimeUtc((([UInt64]$FindData.ftCreationTime.dwHighDateTime -shl 32) + [UInt64]$FindData.ftCreationTime.dwLowDateTime))
    LastWriteTimeUtc  = [DateTime]::FromFileTimeUtc((([UInt64]$FindData.ftLastWriteTime.dwHighDateTime -shl 32) + [UInt64]$FindData.ftLastWriteTime.dwLowDateTime))
    LastAccessTimeUtc = [DateTime]::FromFileTimeUtc((([UInt64]$FindData.ftLastAccessTime.dwHighDateTime -shl 32) + [UInt64]$FindData.ftLastAccessTime.dwLowDateTime))
    Attributes        = $FindData.dwFileAttributes
  })
  # Property: CreationTime
  $Item | Add-Member CreationTime -MemberType ScriptProperty -Value {
    return $this.CreationTimeUtc.ToLocalTime()
  }
  # Property: LastAccessTime
  $Item | Add-Member LastAccessTime -MemberType ScriptProperty -Value {
    return $this.LastAccessTimeUtc.ToLocalTime()
  }
  # Property: LastWriteTime
  $Item | Add-Member LastWriteTime -MemberType ScriptProperty -Value {
    return $this.LastWriteTimeUtc.ToLocalTime()
  }
  # Property: Length
  if ($Item.Attributes -band [IO.FileAttributes]::Directory) {
    $Item.Length = $null
  }
  # Property: Mode
  $Item | Add-Member Mode -MemberType ScriptProperty -Value {
    $Mode = '-----'
    $Mode = switch ($this.Attributes) {
      { $this.Attributes -band [IO.FileAttributes]::Directory } { $Mode -replace '-(....)', 'd$1' }
      { $this.Attributes -band [IO.FileAttributes]::Archive }   { $Mode -replace '(.)-(...)', '$1a$2' }
      { $this.Attributes -band [IO.FileAttributes]::ReadOnly }  { $Mode -replace '(..)-(..)', '$1r$2' }
      { $this.Attributes -band [IO.FileAttributes]::Hidden }    { $Mode -replace '(...)-(.)', '$1h$2' }
      { $this.Attributes -band [IO.FileAttributes]::System }    { $Mode -replace '(....)-', '$1s' }
    }
    return $Mode
  }
  # Property: PSChildName
  $Item | Add-Member PSParentPath -MemberType ScriptProperty -Value {
    return (Split-Path $this.FullName -Leaf)
  }
  # Property: PSIsContainer
  $Item | Add-Member PSIsContainer -MemberType ScriptProperty -Value {
    return [Boolean]($this.Attributes -band [IO.FileAttributes]::Directory)
  }
  # Property: PSParentPath
  $Item | Add-Member PSParentPath -MemberType ScriptProperty -Force -Value {
    return (Split-Path $this.FullName)
  }
  
  # Fabricate a type on this object to let the existing display handlers to operate
  if ($Item.Attributes -band [IO.FileAttributes]::Directory) {
    $Item.PSObject.TypeNames.Add("System.IO.DirectoryInfo")
  } else {
    $Item.PSObject.TypeNames.Add("System.IO.FileInfo")
  }
  $Item.PSObject.TypeNames.Add("System.IO.FileSystemInfo")
  
  $Item
}