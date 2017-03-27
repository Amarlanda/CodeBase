$vms = $null 
 cat c:\amar\VCs.txt | % { 
  $null = Connect-VIServer $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102 
  
  $global:DefaultVIServers | ForEach-Object { 
    $VCName  = $_.Name
    $VCVersion = $_.Version
    $VCBuild = $_.Build
    }
    Write-Host "$VCName"  
    $VCVersion 
    $VCBuild 
    $vms += get-vm | select name, vmhost, powerstate, @{n='Datastores'; e={($_.datastoreidlist | % { Get-Datastore -Id $_ } )-join ", "}}, @{n='VCNAME';e={$VCName}}, @{n='VCVersion';e={$VCVersion}}
    
  Disconnect-viserver $_ -confirm:$false
  
  
}




# $null = Connect-VIServer $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102
  # Connect-VIServer -server ukdtaapp14.uk.kworld.kpmg.com $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102
  
  