$ConfigurationInformation = Import-KSExcelWorksheet Networking.xlsx
$VMHost = "ukdcbvdi004.uk.kworld.kpmg.com"

$ConfigurationInformation |
  Where-Object SwitchName |
  Group-Object SwitchName |
  ForEach-Object {
    $PhysicalPorts = $_.Group | Select-Object -ExpandProperty PhysicalPort | Where-Object { $_ -like "vmnic*" } | Select-Object -Unique
    New-VirtualSwitch -VMHost $VMHost -Name $_.Name -Nic $PhysicalPorts
  }

$ConfigurationInformation |
  Where-Object PortGroupName |
  Group-Object PortGroupName |
  ForEach-Object {
    New-VirtualPortGroup -Name $_.Name -VirtualSwitch (Get-VirtualSwitch -name $($_.Group[0].SwitchName) -vmhost $vmhost) -VlanId $_.Group[0].VlanId
  }
    
$ConfigurationInformation |
  Where-Object PhysicalPort |
  Group-Object PhysicalPort |
  Where-Object { $_.Name -like "vmk*" } |
  ForEach-Object {
    
    $VMKParams = @{}
    if ($_.Group[0].IP) {
      $VMKParams.Add("IP", $_.Group[0].IP)
      $VMKParams.Add("SubnetMask", $_.Group[0].SubnetMask)
    }
    if ($_.Group[0].VMotionEnabled) {
      $VMKParams.Add("VMotionEnabled", $true)
    }
    
    New-VMHostNetworkAdapter -VMHost $VMHost -PortGroup $_.Group[0].PortGroupName -VirtualSwitch (Get-VirtualSwitch -name $_.Group[0].SwitchName -VMHost $VMHost) @VMKParams
  }
