# Set to multiple VC Mode 
if(((Get-PowerCLIConfiguration).DefaultVIServerMode) -ne "Multiple") { 
    Set-PowerCLIConfiguration -DefaultVIServerMode Multiple | Out-Null 
}

# Make sure you connect to your VCs here

# Get the license info from each VC in turn 
$vSphereLicInfo = @() 
$ServiceInstance = Get-View ServiceInstance 
Foreach ($LicenseMan in Get-View ($ServiceInstance | Select -First 1).Content.LicenseManager) { 
    Foreach ($License in ($LicenseMan | Select -ExpandProperty Licenses)) { 
        $Details = "" |Select VC, Name, Key, Total, Used, ExpirationDate , Information 
        $Details.VC = ([Uri]$LicenseMan.Client.ServiceUrl).Host 
        $Details.Name= $License.Name 
        $Details.Key= $License.LicenseKey 
        $Details.Total= $License.Total 
        $Details.Used= $License.Used 
        $Details.Information= $License.Labels | Select -expand Value 
        $Details.ExpirationDate = $License.Properties | Where { $_.key -eq "expirationDate" } | Select -ExpandProperty Value 
        $vSphereLicInfo += $Details 
    } 
} 
$vSphereLicInfo


 cat "C:\Users\uktpalanda\Documents\VMware\KPMG Keys\temp\VCVMware.txt" | % { 
  Connect-VIServer $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102 
  }
  
   $vcs = $global:DefaultVIServers |% { $_ | select @{n='VCName';e={$_.Name}},@{n='VCVersion';e={$_.Version}},@{n='VCBuild';e={$_.Build}}
   }

#$CurrentData = import-clixml C:\Amar\licenseALLVCs.xml


$data = $CurrentData | % { 
   $CurrentVC = $_
   $VCS | ?{ $($currentVC.vc) -like "*$($_.vcname)*" } | select VCName, VCVersion,
    @{n='CurrentVC';e={$currentVC.vc}},
     @{n='KeyType';e={$currentVC.name}},
     @{n='Key';e={$currentVC.key}}, 
     @{n='Used';e={$currentVC.used}},
     @{n='Total';e={$currentVC.total}},
     @{n='Information';e={$currentVC.Information}},
     @{n='ExpirationDate';e={$currentVC.ExpirationDate}}
} 
$data
