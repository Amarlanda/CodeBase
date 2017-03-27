$data = import-csv C:\test\replica.csv
$data = $data | select * , VMid, DatastoreID
$data 

$data | % { 
    $_.VMID  = get-vm -Id $_.id | select -ExpandProperty DatastoreIdList
    $_.DatastoreID = Get-Datastore  -Id $_.VMID
}

$data 