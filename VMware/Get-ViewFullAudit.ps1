

  $pools = get-pool -pool_id "*ukaudit*"
  $data = $pools | % { $_ | Get-desktopvm | Select @{n='UserName';e={$($_.user_displayname).split("\") |select -last 1}},
  @{n='PoolName';e={ $_.pool_id }}, * -ExcludeProperty user_displayname }

  $searcher = new-object DirectoryServices.DirectorySearcher

  $data | select -first 10| % {
    $entry = $_
    $searcher.filter = "(&(objectClass=user)(CN=$($_.username)))"

      if ($_.username) {
        $aduser = $searcher.Findone()
       } else {
      $aduser = $null
      }  

  "displayname", "mail", "lastlogontimestamp", "title", "department", "extensionattribute3", "extensionattribute5" | %{
   $propertyname = $_
   add-member $propertyname -membertype noteproperty -value $(
   if ($aduser) { $aduser.properties.$propertyname } else { "Not assigned" }
    ) -inputobject $entry -force
  }
  $entry
} | select *, @{n='servicearea';e={ $_.extensionattribute3 }},
    #@{n='VDIlastlogon';e={ (Resolve-Path "\\$($_.hostname)\e$\users\$($_.username)*\ntuser.dat" ).Path | Select-Object -expand LastWriteTime }},
    @{n='function';e={ $_.extensionattribute5 }}, 
    @{n='ADuserLastlogonTime';e={$([datetime]::FromFileTime($_.lastlogontimestamp))}} -exclude extensionattribute3, extensionattribute5, lastlogontimestamp | export-csv C:\Amar\ViewFullAudit.csv -notypeinformation

<# $item = 1
 $maxItems = 50
 $VDIList = @()
 $Data | select -first $maxItems | % { 
   Write-Host "Checking for $($_.Username) on $($_.Name)... ($item/$maxItems)" -foregroundColor Yellow
   $NTUserPath = "\\$($_.name)\e$\users\$($_.username)*\ntuser.dat"
   Write-Host $NTUserPath -ForegrounForEach-Object {
     $LastWriteTime = GdColor Magenta
   
     $VDIList += "$($_Name) $($_.Username) $LastWriteTime)" }
     $item++ }
 $VDIList
  		#>