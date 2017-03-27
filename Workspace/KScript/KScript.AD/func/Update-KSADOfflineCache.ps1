function Update-KSADOfflineCache {
  # .SYNOPSIS
  #   Update an entry in the offline cache.
  # .DESCRIPTION
  #
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     11/08/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [String]$Name
  )
  
  $Settings = Get-KSADOfflineCacheSetting -Name @psboundparameters

  if (Test-Path $Settings.CacheFile) {
    # If the CacheFile exists, see if an index does
    if (Test-Path "$($Settings.CacheFile).objectGuidIndex") {
      $Cache = 
    }
  
    # Perhaps we can operate against an index instead
    $Cache = Import-Csv $Settings.CacheFile | ForEach-Object {
      $Cache.Add($_.objectGuid, $_)
    }
  }
  
  if ($Cache.Count -eq 0 -and (Test-Path $Settings.DirSyncCookie)) {
    Remove-Item $Settings.DirSyncCookie
  }
  
  # The cache file will be a Csv
  # Index files allow retrieval of individual elements by position

  Get-KSADObject -LdapFilter $Settings.LdapFilter -Properties $Settings.Properties -DirSync -DirSyncCookie $Settings.DirSyncCookie |
    ForEach-Object {
      
      if ($_.instanceType -ne [KScript.AD.InstanceType]::ObjectIsWriteableOnDirectory -and $ADCache.Contains($_.objectGUID)) {
        Write-Verbose "ADCache: Removing $objectGUID"
      
        $ADCache.Remove($_.objectGUID)
      } else {
        # Generic property handler needed
        $CacheEntry = $_ | Select-Object sAMAccountName, objectGUID, distinguishedName, Type, instanceType,
            @{n='thumbnailPhotoHash';e={ Get-KSHash -ByteArray $_.thumbnailPhoto -Algorithm SHA1 -AsString }} |
          ConvertTo-KSTokenString

        Write-Verbose "ADCache: Adding $CacheEntry"
          
        if ($ADCache.Contains($_.objectGUID)) {
          # Ensure all cached properties are updated for this entry (SamAccountName, previous updates to thumbnailPhoto, etc)
          $ADCache[$_.objectGUID] = $CacheEntry
        } else {
          $ADCache.Add($_.objectGUID, $CacheEntry)
        }
      }
    }
}