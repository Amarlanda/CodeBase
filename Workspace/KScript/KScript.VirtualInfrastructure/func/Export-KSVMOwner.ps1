function Export-KSVMOwner {
  # .SYNOPSIS
  #   Export virtual machine owner information (custom properties) to an Excel file.
  # .DESCRIPTION
  #   Export virtual machine owner information from SCVMM servers to an Excel file.
  #
  #   Owner information is stored in a number of custom properties:
  #
  #     * Service Name
  #     * Service Owner
  #     * Server Role
  #     * Business Function
  #
  #   All information is written to an Excel spreadsheet stored under the ExportPath.
  # .PARAMETER ExportPath
  #   A folder used to store export files. By default the path is set to \\uknasdata18\CORETECH\VMM_Guests.
  # .PARAMETER FileAgeLimit
  #   The script will maintain 7 days worth of Excel files by default. The limit may be adjusted using this parameter. If the reaching the age limit will cause the removal of all records the delete operation will be skipped.
  # .PARAMETER VIEntity
  #   VIEntity is used to target the script at a specific environment. The list of available environments can be seen by running Get-KSVIEntity. If no value is set the current management domain (based on UserDnsDomain) is used.
  # .INPUTS
  #   KScript.VirtualInfrastructure.VIEntity
  #   System.TimeSpan
  #   System.String
  # .EXAMPLE
  #   Export-KSVMOwner
  #
  #   Export all available information from all SCVMM servers within the current management domain. Files and folders are generated based on the description of entity.
  # .EXAMPLE
  #   Get-KSVIEntity -Name ukvmssrv122 | Export-KSVMOwner -ExportPath "C:\Temp"
  #
  #   Export owner information from ukvmwsrv122 to the Temp directory on the current computer.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     01/12/2014 - Chris Dent - Added ClusterName, added HostGroupName.
  #     16/10/2014 - Chris Dent - Added ComputerName to output properties to capture Name / ComputerName mismatches.
  #     29/09/2014 - Chris Dent - Reordered output properties.
  #     26/09/2014 - Chris Dent - Added Business Function custom property.
  #     25/09/2014 - Chris Dent - BugFix: Typo in CSV property name.
  #     23/09/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.VirtualInfrastructure.VIEntity' } )]
    $VIEntity,

    [ValidateScript( { Test-Path $_ -PathType Container  } )]
    [String]$ExportPath = "\\uknasdata18\CORETECH\VMM_Guests",
    
    [TimeSpan]$FileAgeLimit = (New-Timespan -Days 7),
    
    [String]$DateStampFormat = 'yyyyMMddHH0000'
  )

  begin {
    Write-KSLog "Starting $($myinvocation.InvocationName)"
  
    if (-not ((Get-Module virtualmachinemanager) -and (Get-Module failoverclusters))) {
      Write-KSLog "Get-KSClusterSharedVolume must be able to use the modules virtualmachinemanager (SCVMM) and failoverclusters." -LogLevel Error
      break
    }
  }
  
  process {
    if (-not $psboundparameters.ContainsKey('VIEntity')) {
      Write-KSLog "Getting VIEntities from the current management domain."
    
      # Default to the current management domain.
      Get-KSVIEntity -ManagementDomain $env:UserDnsDomain | Export-KSVMOwner @psboundparameters
      break
    }
  
    if ($VIEntity.Type -eq 'SCVMM') {
      Write-KSLog "Exporting from $($VIEntity.Name)"
    
      $CurrentExportPath = "$ExportPath\$($VIEntity.Description)"
      if (-not (Test-Path $CurrentExportPath -PathType Container)) {
        New-Item $CurrentExportPath -Type Directory | Out-Null
      }
      
      # Clear old files from the specified directory - Skip the directory if this leaves no files.
      Write-KSLog "Removing expired export files"
      $AllFiles = Get-ChildItem $CurrentExportPath -File -Filter VMMAssets.*.xlsx | 
        Select-Object Name, FullName, @{n='ToDelete';e={ if ($_.LastWriteTime -lt ((Get-Date) - $FileAgeLimit)) { $true } else { $false } }}
      if (($AllFiles | Where-Object { $_.ToDelete -eq $false }).Count -gt 1) {
        $AllFiles | Where-Object { $_.ToDelete } | ForEach-Object {
          Write-KSLog "Removing $($_.FullName)"
          Remove-Item $_.FullName
        }
      } else {
        Write-KSLog "Abandoning clean up. All files would be removed. If the files are no longer necessary they should be manually deleted." -LogLevel Warning
      }
      
      if (Get-VMMServer $VIEntity.Name) {
        Write-KSLog "Connected to $($VIEntity.Name)."
      
        Write-KSLog "Getting cluster shared volumes."
        $ClusterSharedVolumes = Get-KSClusterSharedVolume -VIEntity $VIEntity
        
        Write-KSLog "Getting virtual machines."
        
        Get-SCVMHostCluster | ForEach-Object {
          $ClusterName = $_.Name
        
          # A work-around to grab the VMHostGroup for each host. SCVMM interoperability prevents access to the VMHostGroup command from a higher version of SCVMM.
          $_ | Get-SCVMHost | ForEach-Object {
            $HostGroupName = Invoke-Command -ComputerName $VIEntity.Name -ArgumentList $VIEntity.Name, $_.Name -Command {
              param(
                $SCVMMServer,
                
                $VMHost
              )
              
              Import-Module virtualmachinemanager; Get-SCVMMServer $SCVMMServer | Out-Null; Get-SCVMHost $VMHost
            } | Select-Object -ExpandProperty VMHostGroup
            
            $_ | Get-SCVirtualMachine |
              Where-Object { $_.VMHost } |
              ForEach-Object {
                Write-KSLog "Virtual machine: $($_.Name)"
              
                $CSV = $_.Location -replace '\\[^\\]+$'
              
                $VM = New-Object PSObject -Property ([Ordered]@{
                  'Service Name'      = $_.CustomProperty['Service Name']
                  'Business Function' = $_.CustomProperty['Business Function']
                  'Service Owner'     = $_.CustomProperty['Service Owner']
                  'Server Role'       = $_.CustomProperty['Server Role']
                  Name                = $_.Name
                  ComputerName        = $_.ComputerName
                  Status              = $_.StatusString
                  Host                = $_.VMHost
                  Site                = ($_.VMHost -replace '^\w{2}(\w{3}).+$', '$1').ToUpper()
                  OperatingSystem     = $_.OperatingSystem.Name
                  CSV                 = $CSV
                  CSVWWN              = ($ClusterSharedVolumes | Where-Object { $_.CSVPath -eq $CSV } | Select-Object -ExpandProperty CSVWWN)
                  ClusterName         = $ClusterName
                  HostGroupName       = $HostGroupName
                  CreatedBy           = $_.Owner
                  CreationDate        = $_.CreationTime
                  ComputerTier        = $_.ComputerTier
                  Description         = $_.Description
                })
                
                if ($_.OperatingSystem.Name -eq 'Unknown') {
                  Write-KSLog "  Unknown operating system found. Attempting to discover."
                
                  if ($_.StatusString -eq 'Running') {
                    Write-KSLog "  Starting WMI operating system discovery."
                  
                    $OperatingSystem = Get-WmiObject Win32_OperatingSystem -ComputerName $_.Name -ErrorAction SilentlyContinue
                    if ($OperatingSystem) {
                      if ($OperatingSystem.OSArchitecture -eq '64-bit') {
                        $OperatingSystemName = "$($_.OperatingSystem.Name) \ $($OperatingSystem.OSArchitecture) edition of $($OperatingSystem.Caption)"
                      } else {
                        $OperatingSystemName = "$($_.OperatingSystem.Name) \ $($OperatingSystem.Caption)"
                      }
                    }
                  } else {
                    Write-KSLog "  Starting AD operating system discovery."
                  
                    $ADComputer = Get-KSADComputer ($_.Name -replace '\..+$') -Properties operatingSystem
                    if ($ADComputer) {
                      $OperatingSystemName = "$($_.OperatingSystem.Name) \ $($ADComputer.OperatingSystem)"
                    }
                  }
                  if ($OperatingSystemName) {
                    Write-KSLog "  Updating operating system value."
                  
                    $VM.OperatingSystem = $OperatingSystemName
                  }
                }
                
                $VM
              }
          }
        } | Export-KSExcelWorksheet "$CurrentExportPath\VMMAssets.$(Get-Date -Format $DateStampFormat).xlsx" -WorksheetName $VIEntity.Name
          
        Write-KSLog "Writing CSV summary to spreadsheet."
        $ClusterSharedVolumes | Export-KSExcelWorksheet "$CurrentExportPath\VMMAssets.$(Get-Date -Format $DateStampFormat).xlsx" -WorksheetName "$($VIEntity.Name)-CSV"
      }
    }
  }
  
  end {
    Write-KSLog "Finished $($myinvocation.InvocationName)"
  }
}