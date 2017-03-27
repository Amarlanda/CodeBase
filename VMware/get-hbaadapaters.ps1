    ($global:DefaultVIServers) | % {
        $DC = $_
         #Connect-VIServer $vmwarehost -user root -pass $pass 
                             
                    $HBAs += Get-View -ViewType HostSystem -Property name, Config.StorageDevice.HostBusAdapter | %{ ## get all HostSystems' .NET View object
                        $viewHost = $_        ## for each HBA that is a HostFibreChannelHba, get some info

                        $viewHost.Config.StorageDevice.HostBusAdapter | ?{$_ -is [VMware.Vim.HostFibreChannelHba]} | %{
                            New-Object -TypeName PSObject -Property @{
                                    VMHostName = $viewHost.Name
                                                               
                                    HBAPortWWN = (("{0:x}" -f $_.PortWorldWideName) -split "(\w{2})" | ?{$_ -ne ""}) -join ":"  ## the HBA Port WWN in hexadecimal, with each octet split by ":"
                                    HBANodeWWN = (("{0:x}" -f $_.NodeWorldWideName) -split "(\w{2})" | ?{$_ -ne ""}) -join ":" ## the HBA Node WWN in hexadecimal, with each octet split by ":"

                                    HBAStatus = $_.Status ## the HBA status ("online", for example)
                                    DC = $DC
                                    } 
                            } 

                    } 

            }

$hbas| Select DC, VMHostName, HBAPortWWN, HBANodeWWN, HBAStatus | Sort VMHostName | Export-Csv "c:\test\$($dc) HBA-WWNs.CSV"
 
 