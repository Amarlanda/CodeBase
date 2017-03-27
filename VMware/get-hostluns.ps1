$hosts = Get-Datacenter -name farm_1 | select -first 1 | % { $_ | get-vmhost }

$hosts | % { 
#$hosts | ? { $_.name -like "*111*" } | %{
$currentHost = $_
  
  $currentHost.datastoreidlist | % {
  $datastoreID =  $_
    $store | ? { $datastoreID -eq  $_.id } | select @{n='Host';e={$currentHost}}, Name, CapacityGB
  } 
} | Sort name | Export-Csv -NoTypeInformation C:\Amar\Datastores.csv



