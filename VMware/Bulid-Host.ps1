
$DC          = "IXE"
$vmhost      = "112"
$MTU         = "1500"
$SwitchName  = "vSW$($counter)-Host$($vmhost)-Role$($Function)"
$counter     = "0"

$Networking = import-csv C:\test\networking.csv
$vmhost = "ukixevsh112.uk.kworld.kpmg.com"
$ConfigForSwitch = $Networking | ? { $_.vmhost -eq "ukixevsh112.uk.kworld.kpmg.com" }

##bulid Switches ##

$ConfigForSwitch |sort switchname | select switchname -Unique | Foreach-object {
   $_
   $counter
   if ($counter -eq 0 ){
       $Function = "Managment"
        [String]$name = "vSW0$($counter)-Role:$($Function)"
       $name
       new-VirtualSwitch -Host $vmhost -Name $name -MTU $MTU
             
       }
      
         if ($counter -ge 1 ){
       $Function = "Production"
       [String]$name = "vSW0$($counter)-Role:$($Function)"
       $name
       new-VirtualSwitch -Host $vmhost -Name $name -MTU $MTU
       
       }
   $counter++ }

   $Networking = import-csv C:\test\networking.csv
$vmhost = "ukixevsh112.uk.kworld.kpmg.com"
$ConfigForSwitch = $Networking | ? { $_.vmhost -eq "ukixevsh112.uk.kworld.kpmg.com" }
   
Foreach ($Record in $ConfigForSwitch){

  
   #$vlandID = $str =$Record.PortGroupName; $str.substring($str.length - 3,3 )
   #if ($vlandID -match "^[\d\.]+$" ){write-host "$vlandID is a number "}
   if ($Record.vlanid){$vlanID = $Record.vlan.id }

   #Get Switch
   $str =$Record.SwitchName;
   $newVSwitch = $str.substring($str.length - 1,1 ) | % { Get-VirtualSwitch -Name "*0$($_)*" -Host $vmhost | select -first 1 }
   
       try {
       $newVSwitch | New-VirtualPortGroup -Name $Record.PortGroupName -VLanId $Record.vlanid
       $newVSwitch
       }

       catch {
       }
       }

new-VirtualSwitch -Host $vmhost -Name $SwitchName

    if ($SwitchName -eq "vSW01-Host$($vmhost)Management" ) { 
        $phNic = $network.PhysicalNic[1]
        $phNic += $network.PhysicalNic[0]
        $portgroups = "",
        "",
        "",
        "",
        ""
    }

 Set-VirtualSwitch -VirtualSwitch $vSwitch -MTU $MTU -Nic $phNic | New-VirtualPortGroup -Name "VLAN-300-DMZ" -VLANID 300
