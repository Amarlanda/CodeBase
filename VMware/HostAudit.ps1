$hostdata = cat .\VCs.txt | % { 
  $null = Connect-VIServer $_ -Force -WarningAction SilentlyContinue

  $global:DefaultVIServers | ForEach-Object { 
    $VCName  = $_.Name
    $VCVersion = $_.Version
    $VCBuild = $_.Build

    get-vmhost | select-object Name, @{n='VMCount';e={($_|get-vm).count }}, @{n='Host utilisation';e={"$([Math]::Round((($_.MemoryUsageGB)/($_.MemoryTotalGB)*100),2))%"}},
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
        @{n='VCName';e={$VCName}},
        @{n='VCVersion';e={$VCVersion}}, PowerState, Manufacturer, state, Model, @{n='MemoryTotalGB';e={[Math]::Round($_.MemoryTotalGB,2)}}, 
        @{n='MemoryUsageGB';e={[Math]::Round($_.MemoryUsageGB,2)}}, NumCpu, CpuTotalMhz, CpuUsageMhz 
  
  }
  Disconnect-viserver -confirm:$false
}
$Hostdata | Export-Csv -NoTypeInformation C:\test\VMwareHostAudit.csv 

