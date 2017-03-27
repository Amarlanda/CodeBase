$xlCSV = 6
$xlXLS = 56
$csvfile = CbeforeHWchange.csv
$xlsfile = CbeforeHWchange.xls

$Excel = New-Object -ComObject Excel.Application
$Excel.visible = $True
$Excel = $Excel.Workbooks.Add()

$Sheet = $Excel.Worksheets.Item(1)
$Sheet.Cells.Item(1,1) = Status
$Sheet.Cells.Item(1,2) = VMName
$Sheet.Cells.Item(1,3) = VMHostname
$Sheet.Cells.Item(1,4) = IPAddress
$Sheet.Cells.Item(1,5) = MacAddress
$Sheet.Cells.Item(1,6) = TotalNics
$Sheet.Cells.Item(1,7) = vNicType
$Sheet.Cells.Item(1,8) = NetworkName
$Sheet.Cells.Item(1,9) = vNicConnected
$Sheet.Cells.Item(1,10) = ToolsVersion
$Sheet.Cells.Item(1,11) = ToolsStatus
$Sheet.Cells.Item(1,12) = ToolsRunningStatus
$Sheet.Cells.Item(1,13) = OS
$Sheet.Cells.Item(1,14) = ESXHost

$intRow = 2

$WorkBook = $Sheet.UsedRange
$WorkBook.Interior.ColorIndex = 19
$WorkBook.Font.ColorIndex = 11
$WorkBook.Font.Bold = $True


#$vms = Get-Folder Lab  Get-VM
$vms = Get-VM

foreach($vm in $vms){

  $vmnic = Get-NetworkAdapter -VM $vm
  $vmview = get-VM $vm  Get-View

if($vm.Guest.State -eq NotRunning){
  $Sheet.Cells.Item($intRow, 1) = [String]$vm.Guest.State
  $Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 3
}
elseif($vm.Guest.State -eq Unknown){
  $Sheet.Cells.Item($intRow, 1) = [String]$vm.Guest.State
  $Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 48
}
else{
  $Sheet.Cells.Item($intRow, 1) = [String]$vm.Guest.State
  $Sheet.Cells.Item($intRow, 1).Interior.ColorIndex = 4
}

$Sheet.Cells.Item($intRow, 2) = $vmview.Name 
$Sheet.Cells.Item($intRow, 3) = $vmview.Guest.HostName
$Sheet.Cells.Item($intRow, 4) = [String]$vm.Guest.IPAddress
$Sheet.Cells.Item($intRow, 5) = $vmnic.MacAddress
$Sheet.Cells.Item($intRow, 6) = $vmview.Guest.Net.Count
$Sheet.Cells.Item($intRow, 7) = [String]$vmnic.Type
$Sheet.Cells.Item($intRow, 8) = $vmnic.NetworkName 
$Sheet.Cells.Item($intRow, 9) = $vmnic.ConnectionState.Connected

if($vmview.Config.Tools.ToolsVersion -eq 8193){
  $Sheet.Cells.Item($intRow, 10) = [String]$vmview.Config.Tools.ToolsVersion
  $Sheet.Cells.Item($intRow, 10).Interior.ColorIndex = 4
}
else{
  $Sheet.Cells.Item($intRow, 10) = [String]$vmview.Config.Tools.ToolsVersion
  $Sheet.Cells.Item($intRow, 10).Interior.ColorIndex = 3
}

if($vmview.Guest.ToolsStatus -eq toolsNotInstalled){
  $Sheet.Cells.Item($intRow, 11) = [String]$vmview.Guest.ToolsStatus
  $Sheet.Cells.Item($intRow, 11).Interior.ColorIndex = 48

}
elseif($vmview.Guest.ToolsStatus -eq toolsNotRunning){
  $Sheet.Cells.Item($intRow, 11) = [String]$vmview.Guest.ToolsStatus
  $Sheet.Cells.Item($intRow, 11).Interior.ColorIndex = 3    
}
elseif($vmview.Guest.ToolsStatus -eq toolsOld){
  $Sheet.Cells.Item($intRow, 10) = [String]$vmview.Config.Tools.ToolsVersion
  $Sheet.Cells.Item($intRow, 10).Interior.ColorIndex = 45
  $Sheet.Cells.Item($intRow, 11) = [String]$vmview.Guest.ToolsStatus
  $Sheet.Cells.Item($intRow, 11).Interior.ColorIndex = 45    
}
else{
  $Sheet.Cells.Item($intRow, 11) = [String]$vmview.Guest.ToolsStatus
  $Sheet.Cells.Item($intRow, 11).Interior.ColorIndex = 4
}    

if($vmview.Guest.ToolsRunningStatus -eq guestToolsRunning){
  $Sheet.Cells.Item($intRow, 12) = $vmview.Guest.ToolsRunningStatus
  $Sheet.Cells.Item($intRow, 12).Interior.ColorIndex = 4
}
else{
  $Sheet.Cells.Item($intRow, 12) = $vmview.Guest.ToolsRunningStatus
  $Sheet.Cells.Item($intRow, 12).Interior.ColorIndex = 3
}

$Sheet.Cells.Item($intRow, 13) = $vmview.Guest.GuestFamily
$Sheet.Cells.Item($intRow, 14) = $vm.Host.Name

$intRow = $intRow + 1}

$WorkBook.EntireColumn.AutoFit()

sleep 5

$Sheet.SaveAs($xlsfile,$xlXLS)
$Sheet.SaveAs($csvfile,$xlCSV) 
