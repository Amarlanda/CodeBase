 $hostdata = cat .\VCs.txt | % { 
  $null = Connect-VIServer $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102 | % { 
  # $null = Connect-VIServer $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102
 # Connect-VIServer -server ukdtaapp14.uk.kworld.kpmg.com $_ -Force -WarningAction SilentlyContinue -user uk\-oper-alanda -pass Dragon102

  $global:DefaultVIServers | ForEach-Object { 
    $VCName  = $_.Name
    $VCVersion = $_.Version
    $VCBuild = $_.Build

    get-vmhost  | select-object Name, 
        @{n='Path';e={ 
          $Path = "" 
          $Current = $_
          do { 
            if ($Current.Parent) { 
              $FolderName = $Current.Parent 
              $Current = $Current.Parent 
            } elseif ($Current.ParentFolder) { 
              $FolderName = $Current.ParentFolder 
              $Current = $Current.ParentFolder 
            } 
            if ($FolderName -notin 'Datacenters', 'host') { 
              $Path = "$FolderName\$Path" 
            } 
          } until (-not $Current.Parent -and -not $Current.ParentFolder) "$($VCName)\$($Path.TrimEnd('\'))"
        }},
        PowerState,
        @{n='VCName';e={$VCName}},
        @{n='VCVersion';e={$VCVersion}} 
      } | % {
      $CurrentVMHost = $_
       get-vm -location $_.name| select Name,
            @{n='VMPath';e={"$($CurrentVMHost.path)\$($_.vmhost)"}}, 
            @{n='VMHostName';e={$CurrentVMhost.name}},
            @{n='VMHostPowerState';e={$CurrentVMhost.PowerState}},
            @{n='VMPowerState';e={$_.PowerState}},
            @{n='VC';e={$CurrentVMhost.VCName}},
            @{n='VersionVC';e={$CurrentVMhost.VCVersion}}

   }
  Disconnect-viserver -confirm:$false
  }
  $Hostdata | Export-Csv -NoTypeInformation C:\Amar\VMHostAudit.csv
}



