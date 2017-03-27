<#function Get-ObservedIPRange {
        param(
                [Parameter(Mandatory=$true,ValueFromPipeline=$true,HelpMessage="Physical NIC from Get-VMHostNetworkAdapter")]
                [VMware.VimAutomation.Client20.Host.NIC.PhysicalNicImpl]
                $Nic
        )
 
        process {
                $hostView = Get-VMHost -Id $Nic.VMHostId | Get-View -Property ConfigManager
                $ns = Get-View $hostView.ConfigManager.NetworkSystem
                $hints = $ns.QueryNetworkHint($Nic.Name)
 
                foreach ($hint in $hints) {
                        foreach ($subnet in $hint.subnet) {
                                $observed = New-Object -TypeName PSObject
                                $observed | Add-Member -MemberType NoteProperty -Name Device -Value $Nic.Name
                                $observed | Add-Member -MemberType NoteProperty -Name VMHostId -Value $Nic.VMHostId
                                $observed | Add-Member -MemberType NoteProperty -Name IPSubnet -Value $subnet.IPSubnet
                                $observed | Add-Member -MemberType NoteProperty -Name VlanId -Value $subnet.VlanId
                                Write-Output $observed
                        }
                }
        }
} #>

$credential = get-credential

$global:DefaultVIServer  | % { Disconnect-viserver $_ -confirm:$false }

"ukvmapp130", "ukvmapp133", "ukvmapp129" | % { connect-viserver $_ -credential $credential 
 
  $CurrentVC = $_
  $hosts = get-vmhost 
  Write-host "checking hosts"
  $hosts| select name, state, uid
  Write-host " checking VCS "
  $global:DefaultVIServer 


$nics += $hosts | ForEach-Object {
  # Create a hash table to track unused interfaces (by recording used interfaces)
  $NICControl = @{}

  # Give the pipeline variable a name so we can use it in later pipeline operations.
  $VMHost = $_

  # Get the host Kernel adapters, but only adapters which do have a port group assigned.
  # The virtual switch will *not* list VMKs as members; they must be requested separately as done here.
  $_ | Get-VMHostNetworkAdapter |
    Where-Object { $_.Name -like 'vmk*' -and $_.PortGroupName } |
    ForEach-Object {
      # Give the pipeline variable a name so we can use it in later pipeline operations.
      $NIC = $_
      
      # Record this NIC if we haven't already.
      if (-not $NICControl.Contains($NIC.Name)) { $NICControl.Add($NIC.Name, "") }
      
      # Get the Virtual Port Group for this NIC.
      Get-VirtualPortGroup -Name $_.PortGroupName -VMHost $VMHost.Name |
        Select-Object `
          @{n='PortGroupName';e={ $_.Name }},
          @{n='VlanID';e={ $_.VlanID }},
          @{n='SwitchName';e={ $_.VirtualSwitch.Name }},
          @{n='NumPorts';e={ $_.VirtualSwitch.NumPorts }},
          @{n='PortsAvailable';e={ $_.VirtualSwitch.NumPortsAvailable }},
          @{n='PhysicalPort';e={ $NIC.Name }},
          @{n='VMHost';e={ $VMHost.Name }},
          @{n='IP';e={ $NIC.IP }},
          @{n='SubnetMask';e={ $NIC.SubnetMask }},
          @{n='MACAddress';e={ $NIC.MAC }},
          @{n='MTU';e={ $NIC.MTU }},
          @{n='VMotionEnabled';e={ $NIC.VMotionEnabled }},
          @{n='CurrentVC'; e={$CurrentVC}},
          DNS,
          DefaultGateway,
          ObservedIPRanges,
          Hostname
    }
  
  # Get all virtual port groups in use on the VMHost. This is used to get the vmnic interfaces.
  $_ |
    Get-VirtualPortGroup |
    ForEach-Object {
      # Give the pipeline variable a name.
      $PortGroup = $_
      
      # Get the Virtual Switch from the port group. Get the NICs associated with this Virtual Switch.
      $_.VirtualSwitch.NIC | ForEach-Object {
        # Hold onto the NIC information
        $NIC = Get-VMHostNetworkAdapter $_ -VMHost $VMHost.Name
        
        # Record this NIC if we haven't already.
        if (-not $NICControl.Contains($NIC.Name)) { $NICControl.Add($NIC.Name, "") }
        
        # Using the NIC; create an object holding all the interesting information.
        $NIC |
          Select-Object `
            @{n='PortGroupName';e={ $PortGroup.Name }},
            @{n='VlanID';e={ $PortGroup.VlanID }},
            @{n='SwitchName';e={ $PortGroup.VirtualSwitch.Name }},
            @{n='NumPorts';e={ $PortGroup.VirtualSwitch.NumPorts }},
            @{n='PortsAvailable';e={ $PortGroup.VirtualSwitch.NumPortsAvailable }},
            @{n='PhysicalPort';e={ $_.Name }},
            @{n='VMHost';e={ $VMHost.Name }},
            IP,
            SubnetMask,
            @{n='MACAddress';e={ $_.MAC }},
            @{n='MTU';e={ $_.MTU }},
            @{n='VMotionEnabled';e={ $_.VMotionEnabled }},
            CurrentVC
      }
    }
  
  # Get all the VMHostNetworkAdapters which we haven't already got. That is, the adapter does not exist in $NICControl.
  # This final pass gets anything which is not bound and therefore does not either have a switch assigned, or a port group assigned.
  $_ |
    Get-VMHostNetworkAdapter |
      Where-Object { -not $NICControl.Contains($_.Name) } |
      Select-Object `
        PortGroupName,
        @{n='VlanID';e={ if ($_.PortGroupName) { (Get-VirtualPortGroup $_.PortGroupName -VMHost $VMHost.Name).VlanID } }},
        SwitchName,
        NumPorts,
        PortsAvailable,
        @{n='PhysicalPort';e={ $_.Name }},
        @{n='VMHost';e={ $VMHost.Name }},
        IP,
        SubnetMask,
        @{n='MACAddress';e={ $_.MAC }},
        @{n='MTU';e={ $_.MTU }},
        @{n='VMotionEnabled';e={ $_.VMotionEnabled }},
        CurrentVC
 }

 Disconnect-viserver $CurrentVC -confirm:$false} 

$nics | Out-GridView



#$data  = $data | select * , @{n="IPSubnet";e={($_ | ? { $_.name -like "*vmnic*" } | Get-ObservedIPRange ).IPSubnet}}
#$data | select VMhost, Name, IP, SubnetMask, Mac, PortGroupName, vMotionEnabled, mtu, FullDuplex, IPSubnet |ft -AutoSize
#$data  = ($esxihost | Get-VMHostNetworkAdapter | ? { $_.name -like "*vmnic*" } | Get-ObservedIPRange)

