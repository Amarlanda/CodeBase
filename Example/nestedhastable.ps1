$ParamsRootFolder = "C:\test\Test"

 #App         Prod  Stagging
 "AdobeDoc    PXL   SAE", 
 "CRM         PCL   SCE",
 "ECC         PEL   SEE",
 "Mobility    PML   SME",
 "EP          PPL   SPE",
 "ProcessIntg PXL   SXE" | %{ $i = $_ | %{ $_.split()| ?{$_}}
    $SIDs += @{"$i[0]" = @{Prod = "$i[1]";Stagging = "$i[2]"}}
 }



$SIDs | % {
   gci $ParamsRootFolder -r | % {

      if ($_.Extension -eq ".txt"){
      (Get-Content $_.FullName) | ForEach-Object {$_ -replace $Prod, $Staging} | Set-Content $_.FullName
      }

      $_ |Copy-Item -Path ($ParamsRootFolder + "\" + $Prod) -Destination ($ParamsRootFolder + "\" + $Staging).ToLower() -Container -Recurse

      }
   }



   "Sids" | %{
Remove-Variable -Name $_ 
}

cls
