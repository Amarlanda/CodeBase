##powershell host build

function New-KpmgVMHost {
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet('BL465','BL685')]
        [String]$Model
        ,
        [Parameter(Mandatory=$true)]
        [ValidateSet('DCA','DCB','DVA')]
        [String]$Location
        ,
        [Parameter(Mandatory=$true)]
        [ValidateSet('Production','Development','ProdDMZ','DevDMZ')]
        [String]$Zone
        ,
        [Parameter(Mandatory=$true)]
        [Int]$Phase = 1
        ,
        [Parameter(Mandatory=$false)]
        [String]$NewComputerName
    )
    begin {
    ## Utility function for renaming network adapters by PCI Bus/Function numbers
    function NameNetAdapter {
        param (
            [String]$Bus,
            [String]$Function,
            [String]$NewName
        )
        process {
            Get-NetAdapterHardwareInfo | Where Bus -EQ $Bus | Where Function -EQ $Function | Rename-NetAdapter -NewName $NewName
        }
    }
    
    ## Breakout function for first phase (run from vfloppy)
    function PhaseFirstRun {
        # copy script and resources to local drive for subsequent logons
        # Copy-Item -Path ([IO.FileInfo]$MyInvocation.MyCommand.Path).Directory.FullName -Destination ($ENV:SystemDrive + '\PostBuild') -Recurse
        
        # Disable DHCP for all adapters
        Set-NetIPInterface -Dhcp Disabled
    
        # Name network adapters
        switch -regex ($Model) {
            '^BL(46|68)5$' { # common adapters for HP 465/685 Blades
                NameNetAdapter -Bus 5 -Function 0 -NewName 'PXE Boot vLAN'
                NameNetAdapter -Bus 4 -Function 0 -NewName 'Management vLAN - Left'
                NameNetAdapter -Bus 4 -Function 1 -NewName 'Management vLAN - Right'
                NameNetAdapter -Bus 5 -Function 4 -NewName 'Payload Trunk - Left'
                NameNetAdapter -Bus 5 -Function 5 -NewName 'Payload Trunk - Right'
            }
            '^BL465$' { # adapters for BL465
                NameNetAdapter -Bus 4 -Function 4 -NewName 'CSV vLAN - Left'
                NameNetAdapter -Bus 4 -Function 5 -NewName 'CSV vLAN - Right'
                NameNetAdapter -Bus 4 -Function 6 -NewName 'Backup Trunk - Left'
                NameNetAdapter -Bus 4 -Function 7 -NewName 'Backup Trunk - Right'
                NameNetAdapter -Bus 5 -Function 6 -NewName 'Live Migration vLAN - Left'
                NameNetAdapter -Bus 5 -Function 7 -NewName 'Live Migration vLAN - Right'
            }
            '^BL685$' { # adapters for BL465
                NameNetAdapter -Bus 4 -Function 4 -NewName 'CSV vLAN - Left'
                NameNetAdapter -Bus 4 -Function 5 -NewName 'CSV vLAN - Right'
                NameNetAdapter -Bus 4 -Function 6 -NewName 'Backup Trunk - Left'
                NameNetAdapter -Bus 4 -Function 7 -NewName 'Backup Trunk - Right'
                NameNetAdapter -Bus 5 -Function 6 -NewName 'Live Migration vLAN - Left'
                NameNetAdapter -Bus 5 -Function 7 -NewName 'Live Migration vLAN - Right'
            }
        }
        
        # Disable unused adapters
        Get-NetAdapter -Name Ethernet* | Disable-NetAdapter -Confirm:$false
        Get-NetAdapter -Name 'PXE Boot vLAN' | Disable-NetAdapter -Confirm:$false
        
        # Install required features for host
        Install-WindowsFeature FS-FileServer,Hyper-V,Multipath-IO,Failover-Clustering,RSAT-Clustering-Powershell
        
        # Set up bootstrap network adapter
        switch ($Location) { # TODO - switch these round to match rest of script
            'DCA' {switch ($Zone) {
                'Production'  {$tempMgmtAddress = '10.203.118.110'; $mgmtPrefixLength = 25; $mgmtGateway = '10.203.118.1'}
                'ProdDMZ'     {$tempMgmtAddress = '10.203.118.239'; $mgmtPrefixLength = 25; $mgmtGateway = '10.203.118.129'}
                default {throw "$Zone is not a valid zone for location $Location"}
            }}
            'DCB' {switch ($Zone) {
                'Production'  {$tempMgmtAddress = '10.203.119.110'; $mgmtPrefixLength = 25; $mgmtGateway = '10.203.119.1'}
                'ProdDMZ'     {$tempMgmtAddress = '10.203.119.239'; $mgmtPrefixLength = 25; $mgmtGateway = '10.203.119.129'}
                default {throw "$Zone is not a valid zone for location $Location"}
            }}
            'DVA' {switch ($Zone) {
                'Development' {$tempMgmtAddress = '10.203.130.120'; $mgmtPrefixLength = 25; $mgmtGateway = '10.203.130.1'}
                'DevDMZ'      {$tempMgmtAddress = '10.203.130.250'; $mgmtPrefixLength = 25; $mgmtGateway = '10.203.130.129'}
                default {throw "$Zone is not a valid zone for location $Location"}
            }}
        }
        New-NetIPAddress -InterfaceAlias 'Management vLAN - Left' -IPAddress $tempMgmtAddress -PrefixLength $mgmtPrefixLength -DefaultGateway $mgmtGateway
        Set-DnsClientServerAddress -InterfaceAlias 'Management vLAN - Left' -ServerAddresses 10.216.163.40
        
        # Join domain
        $params = @{
            "DomainName" = "uk.kworld.kpmg.com"
        }
        if ($NewComputerName) {
            Rename-Computer -NewName $NewComputerName
            $params.Add("Options","JoinWithNewName")
        }
        Add-Computer @params -Restart
    }
    
    ## Breakout function for third phase (VMM Setup)
    function PhaseVMMSetup {
        # connect to VMM server
        $vmmServerSession = New-PSSession -ComputerName 'UKVMSSRV122.uk.kworld.kpmg.com'
        
        # Add VM Host to host group
        switch ($Zone) {
            'Production'  {$vmmHostGroupName = 'Prod General'}
            'Development' {$vmmHostGroupName = 'Dev General'}
            'ProdDMZ'     {$vmmHostGroupName = 'Prod DMZ General'}
            'DevDMZ'      {$vmmHostGroupName = 'Dev DMZ General'}
        }
        $newHostName = $ENV:COMPUTERNAME
        Invoke-Command -Session $vmmServerSession -ScriptBlock {
            # Add host to VMM
            Get-SCVMMServer -ComputerName 'UKVMSSRV122'
            Add-SCVMHost -VMHostGroup (Get-SCVMHostGroup -Name $Using:vmmHostGroupName) -ComputerName $Using:newHostName -Credential (Get-SCRunAsAccount 'Hyper-V Admin')
            $vmHost = Get-SCVMHost -ComputerName $Using:newHostName # because above command doesn't pass through, thanks MS
        }
        
        # Create variables in VMM session for all physical NICs
        switch -regex ($Model) {
            '^BL(46|68)5$' { # common adapters for HP 465/685 Blades
                Invoke-Command -Session $vmmServerSession -ScriptBlock {
                    $pnic_MgmtLeft       = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Management vLAN - Left'
                    $pnic_MgmtRight      = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Management vLAN - Right'
                    $pnic_MigrationLeft  = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Live Migration vLAN - Left'
                    $pnic_MigrationRight = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Live Migration vLAN - Right'
                    $pnic_CSVLeft        = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'CSV vLAN - Left'
                    $pnic_CSVRight       = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'CSV vLAN - Right'
                    $pnic_PayloadLeft    = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Payload Trunk - Left'
                    $pnic_PayloadRight   = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Payload Trunk - Right'
                    $pnic_BackupLeft     = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Backup Trunk - Left'
                    $pnic_BackupRight    = Get-SCVMHostNetworkAdapter -VMHost $vmHost | where ConnectionName -EQ 'Backup Trunk - Right'
                }
            }
        }
        
        # Create variables in VMM session for VMM networking components
        switch ($Zone) {
            'Production' {
                switch ($Location) {
                    'DCA' {
                        $mgmtVlan        = '420'
                        $mgmtSubnet      = '10.203.118.0/25'
                        $migrationSubnet = '192.168.4.0/22'
                    }
                    'DCB' {
                        $mgmtVlan        = '520'
                        $mgmtSubnet      = '10.203.119.0/25'
                        $migrationSubnet = '192.168.56.0/22'
                    }
                }
                $migrationVlan     = '950'
                $csvVlan           = '960'
                $backupVlan        = '1510'
                $switchPrefix = 'Production'
            }
            'ProdDMZ' {
                switch ($Location) {
                    'DCA' {
                        $mgmtVlan        = '421'
                        $mgmtSubnet      = '10.203.118.128/25'
                        $migrationSubnet = '192.168.8.0/23'
                    }
                    'DCB' {
                        $mgmtVlan        = '521'
                        $mgmtSubnet      = '10.203.119.128/25'
                        $migrationSubnet = '192.168.60.0/22'
                    }
                }
                $migrationVlan     = '951'
                $csvVlan           = '961'
                $backupVlan        = '1511'
                $switchPrefix = 'Prod DMZ'
            }
            'Development' {
                switch ($Location) {
                    'DVA' {
                        $mgmtVlan        = '422'
                        $mgmtSubnet      = '10.203.130.128/25'
                        $migrationSubnet = '192.168.10.0/23'
                    }
                }
                $migrationVlan     = '952'
                $csvVlan           = '962'
                $backupVlan        = '1502'
                $switchPrefix = 'Development'
                #TODO
            }
            'DevDMZ' {
                #TODO
            }
        }
        Invoke-Command -Session $vmmServerSession -ScriptBlock {
            # logical switches
            $switch_Mgmt      = Get-SCLogicalSwitch -Name "$Using:switchPrefix Management Switch"
            $switch_Migration = Get-SCLogicalSwitch | where Description -eq "vLAN $Using:migrationVlan"
            $switch_CSV       = Get-SCLogicalSwitch | where Description -eq "vLAN $Using:csvVlan"
            $switch_Payload   = Get-SCLogicalSwitch -Name "$Using:switchPrefix Payload Trunk Switch"
            $switch_Backup    = Get-SCLogicalSwitch -Name "$Using:switchPrefix Backup Trunk Switch"
            
            # vm networks (Note - host has no presence on payload vLAN, so vmnet_Payload does not exist)
            $vmnet_Mgmt      = Get-SCVMNetwork | where Description -eq "vLAN $Using:mgmtVlan"
            $vmnet_Migration = Get-SCVMNetwork | where Description -eq "vLAN $Using:migrationVlan"
            $vmnet_CSV       = Get-SCVMNetwork | where Description -eq "vLAN $Using:csvVlan"
            $vmNet_Backup    = Get-SCVMNetwork | where Description -eq "vLAN $Using:backupVlan"
            
            # vm subnet for backup (to support host virtual adapter on trunked switch)
            $vmsub_Backup = Get-SCVMSubnet -Subnet (Get-SCVMSubnet | % {$_.SubnetVLans} | where VLanID -eq $Using:backupVlan).Subnet
            
            # ip pools (Note - host has no presence on payload vLAN, so pool_Payload does not exist)
            $pool_Mgmt      = Get-SCStaticIPAddressPool -Subnet $Using:mgmtSubnet
            $pool_Migration = Get-SCStaticIPAddressPool -Subnet $Using:migrationSubnet
            $pool_CSV       = Get-SCStaticIPAddressPool -LogicalNetworkDefinition (Get-SCLogicalNetworkDefinition -LogicalNetwork $vmnet_CSV.LogicalNetwork)
            $pool_Backup    = Get-SCStaticIPAddressPool -VMSubnet $vmsub_Backup
            
            # uplink port profile sets
            $upps_Mgmt      = Get-SCUplinkPortProfileSet -LogicalSwitch $switch_Mgmt | where NativeUplinkPortProfile -eq (Get-SCNativeUplinkPortProfile | where Description -eq "vLAN $Using:mgmtVlan")
            $upps_Migration = Get-SCUplinkPortProfileSet -LogicalSwitch $switch_Migration
            $upps_CSV       = Get-SCUplinkPortProfileSet -LogicalSwitch $switch_CSV
            $upps_Payload   = Get-SCUplinkPortProfileSet -LogicalSwitch $switch_Payload
            $upps_Backup    = Get-SCUplinkPortProfileSet -LogicalSwitch $switch_Backup
            
            # port classifications (Note - host has no presence on payload vLAN, so class_Payload does not exist)
            $class_Mgmt      = Get-SCPortClassification -Name 'Host Management'
            $class_Migration = Get-SCPortClassification -Name 'Live migration  workload' # double-space typo is from VMM as supplied by Microsoft!
            $class_CSV       = Get-SCPortClassification -Name 'Cluster Shared Volume'
            $class_Backup    = Get-SCPortClassification -Name 'Backup'
        }
        
        # Create and execute networking job on VMM Server
        Invoke-Command -Session $vmmServerSession -ScriptBlock {
            # create a guid for parallel operations (performed in Set-SCVMHost)
            $jobid = [guid]::NewGuid().guid
            
            # initially disable placement and management on all adapters
            Get-SCVMHostNetworkAdapter -VMHost $vmHost | Set-SCVMHostNetworkAdapter -AvailableForPlacement $false -UsedForManagement $false -JobGroup $jobid
            
            # Apply uplink port profile sets to host adapters and enable placement/management
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_MgmtLeft       -UplinkPortProfileSet $upps_Mgmt      -JobGroup $jobid -UsedForManagement $true
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_MgmtRight      -UplinkPortProfileSet $upps_Mgmt      -JobGroup $jobid -UsedForManagement $true
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_MigrationLeft  -UplinkPortProfileSet $upps_Migration -JobGroup $jobid
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_MigrationRight -UplinkPortProfileSet $upps_Migration -JobGroup $jobid
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_CSVLeft        -UplinkPortProfileSet $upps_CSV       -JobGroup $jobid
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_CSVRight       -UplinkPortProfileSet $upps_CSV       -JobGroup $jobid
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_PayloadLeft    -UplinkPortProfileSet $upps_Payload   -JobGroup $jobid -AvailableForPlacement $true
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_PayloadRight   -UplinkPortProfileSet $upps_Payload   -JobGroup $jobid -AvailableForPlacement $true
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_BackupLeft     -UplinkPortProfileSet $upps_Backup    -JobGroup $jobid -AvailableForPlacement $true
            Set-SCVMHostNetworkAdapter -VMHostNetworkAdapter $pnic_BackupRight    -UplinkPortProfileSet $upps_Backup    -JobGroup $jobid -AvailableForPlacement $true
            
            # Create logical switch instances on host - management switch contains right NIC only until we remove the temporary address from the left
            New-SCVirtualNetwork -VMHost $vmHost -VMHostNetworkAdapters $pnic_MgmtRight                             -LogicalSwitch $switch_Mgmt      -JobGroup $jobid
            New-SCVirtualNetwork -VMHost $vmHost -VMHostNetworkAdapters @($pnic_MigrationLeft,$pnic_MigrationRight) -LogicalSwitch $switch_Migration -JobGroup $jobid
            New-SCVirtualNetwork -VMHost $vmHost -VMHostNetworkAdapters @($pnic_CSVLeft,$pnic_CSVRight)             -LogicalSwitch $switch_CSV       -JobGroup $jobid
            New-SCVirtualNetwork -VMHost $vmHost -VMHostNetworkAdapters @($pnic_PayloadLeft,$pnic_PayloadRight)     -LogicalSwitch $switch_Payload   -JobGroup $jobid
            New-SCVirtualNetwork -VMHost $vmHost -VMHostNetworkAdapters @($pnic_BackupLeft,$pnic_BackupRight)       -LogicalSwitch $switch_Backup    -JobGroup $jobid
            
            # Create host virtual NICs (Note - host has no presence on payload vLAN)
            New-SCVirtualNetworkAdapter -VMHost $vmHost -Name 'Management vNIC'     -VMNetwork $vmnet_Mgmt      -LogicalSwitch $switch_Mgmt      -PortClassification $class_Mgmt      -IPv4AddressType 'Static' -IPv4AddressPool $pool_Mgmt      -MACAddressType 'Static' -MACAddress '00:00:00:00:00:00' -JobGroup $jobid -VLanEnabled $false
            New-SCVirtualNetworkAdapter -VMHost $vmHost -Name 'Live Migration vNIC' -VMNetwork $vmnet_Migration -LogicalSwitch $switch_Migration -PortClassification $class_Migration -IPv4AddressType 'Static' -IPv4AddressPool $pool_Migration -MACAddressType 'Static' -MACAddress '00:00:00:00:00:00' -JobGroup $jobid -VLanEnabled $false
            New-SCVirtualNetworkAdapter -VMHost $vmHost -Name 'CSV vNIC'            -VMNetwork $vmnet_CSV       -LogicalSwitch $switch_CSV       -PortClassification $class_CSV       -IPv4AddressType 'Static' -IPv4AddressPool $pool_CSV       -MACAddressType 'Static' -MACAddress '00:00:00:00:00:00' -JobGroup $jobid -VLanEnabled $false
            New-SCVirtualNetworkAdapter -VMHost $vmHost -Name 'Host Backup vNIC'    -VMNetwork $vmnet_Backup    -LogicalSwitch $switch_Backup    -PortClassification $class_Backup    -IPv4AddressType 'Static' -IPv4AddressPool $pool_Backup    -MACAddressType 'Static' -MACAddress '00:00:00:00:00:00' -JobGroup $jobid -VMSubnet $vmsub_Backup
            
            # Execute the job group
            Set-SCVMHost -VMHost $vmHost -JobGroup $jobid
        }
        
        # Disable DNS registration on all except the Management virtual NIC, and update registration
        Get-DnsClient | Set-DnsClient -RegisterThisConnectionsAddress $false
        Set-DnsClient -InterfaceAlias 'vEthernet (Management vNIC)' -RegisterThisConnectionsAddress $true
        Register-DnsClient
        
        # Clear the DNS cache on the VMM server so that it doesn't lose comms with this
        Invoke-Command -Session $vmmServerSession -ScriptBlock {Clear-DnsClientCache}
        
        # Configure MPIO
        Get-MSDSMSupportedHW | Remove-MSDSMSupportedHW
        New-MSDSMSupportedHW -VendorID '3PARdata' -ProductID 'VV'
        Update-MPIOClaimedHW -Confirm:$false

        # Remove the temporary IP address from the left management NIC
        Set-DnsClientServerAddress -InterfaceAlias 'Management vLAN - Left' -ResetServerAddresses
        Get-NetAdapter -Name 'Management vLAN - Left' | Remove-NetIPAddress -Confirm:$false
        Get-NetRoute -InterfaceAlias 'Management vLAN - Left' | Remove-NetRoute -Confirm:$false
        
        # Add the left NIC to the management switch
        Invoke-Command -Session $vmmServerSession -ScriptBlock {
            $vnet_Mgmt = Get-SCVirtualNetwork -VMHost $vmHost | Where VMHostNetworkAdapters -eq $pnic_MgmtRight
            Set-SCVirtualNetwork -VirtualNetwork $vnet_Mgmt -VMHostNetworkAdapters @($pnic_MgmtLeft,$pnic_MgmtRight) -LogicalSwitch $switch_mgmt
        }
        
        # Set up next phase and restart
        #TODO - write auto admin logon details to registry
        Restart-Computer -Force
    }
    }
    process {
        $ErrorActionPreference = "Stop"
        switch ($Phase) {
            1 {PhaseFirstRun}
            2 {PhaseVMMSetup}
        }
    }
}
