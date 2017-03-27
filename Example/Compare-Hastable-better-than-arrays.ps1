   $vcvdis = import-csv c:\amar\vdi2.csv 
 $viewvdis = import-csv c:\amar\vdi.csv
$vcvdishash = @{} 
$viewvdishash = @{} 

    $viewvdis | ForEach-Object { 
    $viewvdishash.Add($_.machine, $_) 
    } 

   
    $vcvdis | ForEach-Object { 
    $vcvdishash.Add($_.name, $_) 
    } 

    # On VC, not in View 
    $vcvdis | ?{ -not $viewvdishash.Contains($_.name) } 

    # On View, not in VC 
    $viewvdishash | ?{ -not $vcvdishash.Contains($_.machine) } 

    # On both 
    $viewvdis | ?{ $vcvdishash.Contains($_.machine) }

