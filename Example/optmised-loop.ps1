

$vcvdis = $(import-csv c:\amar\vdi2.csv  | sort name) 
$viewvdis = $(import-csv c:\amar\vdi.csv | sort machine)

$matchedVC =@()
$notmatchedVC =@()

$viewvdis = $viewvdis | select *, "matched"
$vcvdis = $vcvdis | select *, "matched"
$i =0
$viewvdis | % {                                                                                   ## looping through VC VDIs


  $currentVDI = $_
   Write-host "Loop $i - checking $($currentVDI.machine)" -ForegroundColor blue                             ## if i remove the sub-expressions why does it mess up!

    $vcvdis  | % {                                                                                         ## looping through View VDIs
    
    Write-host "Loop 1 - checking $($currentVDI.machine)  with $($_.name)" -ForegroundColor Green
      if ($_.name -like "*$($currentVDI.machine)*" ){
      Write-host "Matched $($currentVDI.machine) with $($_.name)"  -ForegroundColor red
      #$viewvdis.Remove($currentVDI)                                                                              sooooo slow becuase i cant skip the data i have already matched!
      #$vcvdis.Remove($_)
      $matchedVC += $_
      $currentVDI.matched = "TRUE"
      $_.matched = "TRUE"
      }

      else {
      $notmatchedVC += $_
      }
            
    }
    if ($($currentVDI.matched)){ 
    $_.matched = "True" }
    $currentVDI = $null
   $i++

} 

$matchedVC
#$notmatchedVC



    