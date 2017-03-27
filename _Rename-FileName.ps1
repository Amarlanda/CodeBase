

$OldExtension = ".ps1"
$NewExtension = ".txt"

gci "C:\_AJ\Scripts" -r | % {

    if($_.Extension -eq $OldExtension -and (-not $_.name.contains("Rename-FileName"))){
        $_ | rename-item -newname{$_.name  -replace ('\'+ $OldExtension +'$'),$NewExtension}
        $count ++
    } 
        
    if($_.Extension -eq $NewExtension -and (-not $_.name.contains("Rename-FileName"))){
        $_ | rename-item -newname{$_.name  -replace ('\'+ $NewExtension +'$'),$OldExtension}
        $count ++
    }
    
}
start-sleep 3.5
write-host " changed $count files"