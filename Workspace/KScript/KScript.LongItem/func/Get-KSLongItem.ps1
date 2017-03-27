function Get-KSLongItem {
  [CmdLetBinding()]
  param(
    [String]$Name = $PWD.Path,
    
    [Switch]$Recurse
  )

  $Name = (Get-Item $Name).FullName
  
  $FindData = New-Object KScript.LongItem+WIN32_FIND_DATA
  $FindHandle = [KScript.LongItem]::FindFirstFile("\\?\$Name\*", [Ref]$FindData)

  if ($FindHandle -ne -1) {
    $Found = $true
    do {
      $Item = NewKSLongItemObject -FindData $FindData -Name $Name

      if ($Item.Name -notin '.', '..') {
        $Item
      }
      
      if ($Recurse -and $Item.PSIsContainer) {
        Get-KSLongItem -Name $Item.FullName
      }
      
      $Found = [KScript.LongItem]::FindNextFile($FindHandle, [Ref]$FindData)
    } until (-not $Found)
  }
}