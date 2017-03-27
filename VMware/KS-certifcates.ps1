Import-Module KScript.AD, KScript.CertificateManagement, KScript.CMDB, KScript.DnsResolver, KScript.Utility

# This script is intended to be run in chunks, in some cases in parallel (hence the excessive use of files). If run from scratch the entire process will take close to a day to complete (slow data sources).

#
# Grab certificate template information from Active Directory
#   Run time:     Fast
#   Execute when: CA information file is being refreshed

# This is used to populate the CertificateTemplateName value when querying the CA.
$CertificateTemplates = @{}
Get-KSADCertificateTemplate | ForEach-Object {
  $CertificateTemplates.Add($_.'msPKI-Cert-Template-OID', $_.Name)
}

#
# Get the current list of issued certificates from the CA (expiring between now and 1st April)
#   Run time:     Extremely slow
#   Execute when: CA information file is being refreshed

# Note: This section takes a *very* long time to run. Don't refresh the file unless you need to.
if (Test-Path AllExpiringCertificates.csv) { Remove-Item AllExpiringCertificates.csv }
# Several of the fields here are created but not used yet. They're populated when other data sources are merged into this one.
# This attempts to get the issued certificiates from the CA.
"euwatsrv23\KPMG Internal Issuing CA EU01", "euixesrv23\KPMG Internal Issuing CA EU02" |
  ForEach-Object {
    $CA = $_
  
    # Need to split the filter into more manageable chunks to pick up all the certificate requests
    $IssuingStart = (Get-Date).AddYears(-2).Date
    $IssuingTimeSpan = New-TimeSpan -Start $IssuingStart -End (Get-Date '01/04/2015')
    # Divide it into manageable segments, hopefully to avoid the administrative session concurrency limit.
    $MaxDaysPerQuery = [Math]::Ceiling($IssuingTimeSpan.TotalDays / 10)
    
    $DaysOffset = 0; $i = 0
   
    do {
      $NotBeforeStart = $IssuingStart.AddDays($MaxDaysPerQuery * $i++)
      $NotBeforeEnd = $NotBeforeStart.AddDays($MaxDaysPerQuery).AddSeconds(-1)
    
      # KPMGServerAuthentication, KPMGWebServerAuthentication, KPMGWebServerAuthentication(1024)
      $OIDs = '1.3.6.1.4.1.311.21.8.9498124.6089089.6112135.1244830.1219107.191.10703806.1608417',
              '1.3.6.1.4.1.311.21.8.9498124.6089089.6112135.1244830.1219107.191.138660.11667527',
              '1.3.6.1.4.1.311.21.8.9498124.6089089.6112135.1244830.1219107.191.4020754.2116913'
              
      $OIDs | ForEach-Object {
        $OID = $_
      
        Write-Host "$($CA): $($NotBeforeStart.ToString('dd/MM/yyyy')) to $($NotBeforeEnd.ToString('dd/MM/yyyy')) and template $OID"
        
        # Issued requests created between NotBeforeStart and NotBeforeEnd using the KPMGWebServerAuthentication template.
        # Thumbprint must be generated based on the public key for matching later.
        Get-KSCACertificateRequest -CA $CA -Filter "NotBefore -ge '$($NotBeforeStart.ToString())' -and NotBefore -le '$($NotBeforeEnd.ToString())' -and CertificateTemplate -eq '$OID'" -Issued |
          Select-Object `
            CommonName,
            @{n='UsedOnComputerName';e={ $_.ComputerName -replace '\..+$' }},
            UsedForService,
            BoundInterface,
            @{n='CertificateTemplateName';e={ $CertificateTemplates[$_.CertificateTemplate] }},
            NotAfter,
            NotBefore,
            CA,
            Organization,
            Country,
            @{n='RequestedFromComputerName';e={ $_.ComputerName }},
            @{n='RequesterName';e={ $_.'Request.RequesterName' }},
            @{n='RequesterDomain';e={ $_.'Request.RequesterName' -replace '\\.+$' }},
            ServiceName,
            BusinessFunction,
            ServiceOwner,
            ServerRole,
            @{n='CertificateTemplateOID';e={ $_.CertificateTemplate }},
            RequestID,
            @{n='Thumbprint';e={ $_ | ConvertTo-KSX509Certificate | Select-Object -ExpandProperty Thumbprint }} |
          Where-Object { $_.Thumbprint } |
          Export-Csv "PKI-AllExpiringCertificates-CA.csv" -Append -NoTypeInformation
      }
        
      $DaysOffset += $MaxDaysPerQuery
    } until ($DaysOffset -ge $IssuingTimeSpan.TotalDays)
  }
  
#
# Query the CMDB for certificate information. Include SupportedCiphers to allow partial enumeration of certificates in non-MS stores.
#   Run time:     Slow
#   Execute when: CMDB information file is being refreshed

# Please note generating this takes a long time, there are just under 1600 asset records to look at and it's all done from an SMB share.
Get-KSAsset -List | ForEach-Object {
  $AssetName = $_.Name

  Write-Host $AssetName
  
  $Certificates = Get-KSAsset $_.Name -Item Certificates -Filter @{HasPrivateKey='True'} | Where-Object { $_.NotAfter -lt (Get-Date '01/04/2015') -and $_.Issuer -match 'CA EU' }
  $SupportedCiphers = Get-KSAsset $_.Name -Item SupportedCiphers -Filter @{CertificateIssuer='EU'} |
    Group-Object Port, InterfaceName | ForEach-Object {
      $_.Group[0]
    }
  
  $CommonNames = @{}
  $Certificates | ForEach-Object {
    if ($_.Subject -match 'CN=([^,]+)(,|$)') {
      $CommonName = $matches[1]
      if ($_.Issuer -match 'KPMG Internal Issuing ([^,]+)') {
        $Issuer = $matches[1]
      } else {
        $Issuer = $null
      }

      if (-not $CommonNames.Contains($CommonName)) {
        Write-Host "  Adding $CommonName to list"
      
        $Certificate = New-Object PSObject -Property ([Ordered]@{
          ServerName     = $AssetName
          CommonName     = $CommonName
          Issuer         = $Issuer
          NotAfter       = $_.NotAfter
          NotBefore      = $_.NotBefore
          Thumbprint     = $_.Thumbprint
          Service        = $null
          ServiceVersion = $null
          InterfaceName  = $null
          Port           = $null
        })
      
        $CommonNames.Add($CommonName, $Certificate)
      }
    } else {
      Write-Host "  Bad subject $($_.Subject)" -ForegroundColor Cyan
    }
  }
  $SupportedCiphers | ForEach-Object {
    if ($_.CertificateCommonName -match '^([^/]+)(/|$)') {
      $CommonName = $matches[1]
      
      if ($CommonNames.Contains($CommonName)) {
        # Equal to or adjusted for datlight saving time.
        if ($CommonNames[$CommonName].NotBefore -eq $_.CertificateInception -or $CommonNames[$CommonName].NotBefore -eq $_.CertificateInception.AddHours(1)) {
          Write-Host "  Updating service information for $CommonName"
        
          $Certificate = $CommonNames[$CommonName]
          $Certificate.Service = $_.Service
          $Certificate.ServiceVersion = $_.Version
          $Certificate.InterfaceName = $_.InterfaceName
          $Certificate.Port = $_.Port
        }
      } else {
        if ($_.CertificateExpiration -gt (Get-Date)) {
          Write-Host "  New certificate found $CommonName" -ForegroundColor Yellow

          $Certificate = New-Object PSObject -Property ([Ordered]@{
            ServerName     = $AssetName
            CommonName     = $CommonName
            Issuer         = $_.CertificateIssuer
            NotAfter       = $_.CertificateExpiration
            NotBefore      = $_.CertificateInception
            Thumbprint     = $null
            Service        = $_.Service
            ServiceVersion = $_.Version
            InterfaceName  = $_.InterfaceName
            Port           = $_.Port
          })
          
          $CommonNames.Add($CommonName, $Certificate)
        } else {
          Write-Host "  Expired certificate bound to service $CommonName / $($_.Services) $($_.Version)" -ForegroundColor Red
        }
      }
    } else {
      Write-Host "  Failed to extract common name $($_.CertificateCommonName)" -ForegroundColor Green
    }
  }
  
  $CommonNames.Keys | ForEach-Object { $CommonNames[$_] }
} | Export-Csv PKI-AuditedCertificates-CMDBCert.csv -NoTypeInformation

#
# Query the CMDB again, this time for network interfaces in case we can use these to get a ComputerName after resolving a CommonName to an IP
#   Run time:     Slow
#   Execute when: Every time a new merged file is generated

$CMDBIPAddresses = @{}
Get-KSAsset -Item NetworkInterfaces | ForEach-Object {
  $AssetName = $_.AssetName
  $_.IPAddress | ForEach-Object {
    if ($_ -and ([IPAddress]$_).AddressFamily -eq 'InterNetwork') {
      if (-not $CMDBIPAddresses.Contains([IPAddress]$_)) {
        $CMDBIPAddresses.Add([IPAddress]$_, $AssetName)
      }
    }
  }
}

#
# Import the information harvested from the CMDB into memory for merging later.
#   Run time:     Fast
#   Execute when: Every time a new merged file is generated

$AuditedCertificates = @{}
Import-Csv PKI-AuditedCertificates-CMDB.csv | Where-Object { $_.Thumbprint } | ForEach-Object {
  # Used on, used for, InterfaceName, Port
  $BindingInfo = $_ | Select-Object ServerName, ServiceVersion, InterfaceName, Port
  if ($AuditedCertificates.Contains($_.Thumbprint)) {
    $AuditedCertificates[$_.Thumbprint] += $BindingInfo
  } else {
    $AuditedCertificates.Add($_.Thumbprint, @($BindingInfo))
  }
}

#
# Import organisation information about virtual machines
#   Run time:     Moderate
#   Execute when: Every time a new merged file is generated

# Ignore errors
$VirtualMachines = @{}
Get-ChildItem \\uknasdata18\CORETECH\VMM_Guests\*\*.xlsx |
  Sort-Object LastWriteTime -Descending |
  Select-Object -First 2 |
  ForEach-Object {
    Import-KSExcelWorksheet $_.FullName -WorksheetName VirtualMachines |
      Where-Object { $_.Status -eq 'Running' } |
      ForEach-Object {
        $OrgInfo = $_ | Select-Object 'Service Name', 'Business Function', 'Service Owner', 'Server Role'
        $VirtualMachines.Add(($_.ComputerName -replace '\..+$'), $OrgInfo)
      }
  }
  
  
#
# Merge everything

# Treat the export from the CA as the authoritative data source

# First pass: Update certificate binding information if we have any
#   Run time:     Fast
#   Execute when: Every time a new merged file is generated
Import-Csv PKI-AllExpiringCertificates-CA.csv | ForEach-Object {

  $ExpiringCertificate = $_
  # See if we have any where-used information for this certificate
  if ($AuditedCertificates.Contains($_.Thumbprint)) {
    $AuditedCertificates[$_.Thumbprint] | ForEach-Object {
      $NewExpiringCertificateObject = $ExpiringCertificate | Select-Object *
      $NewExpiringCertificateObject.UsedOnComputerName = $_.ServerName
      $NewExpiringCertificateObject.UsedForService = $_.ServiceVersion
      if ($_.InterfaceName -and $_.Port) {
        $NewExpiringCertificateObject.BoundInterface = "$($_.InterfaceName):$($_.Port)"
      }
      
      $NewExpiringCertificateObject
    }
  } else {
    # Don't modify or expand the record
    $_
  }
} | Export-Csv PKI-AllExpiringCertificates-CMDBCert.csv -NoTypeInformation

# Second pass: Add DNS information based on the CommonName.
#   Ignore the errors and warnings generated by this section.
#   Run time:     Moderate
#   Execute when: Every time a new merged file is generated
Import-Csv PKI-AllExpiringCertificates-CMDBCert.csv | ForEach-Object {
  # If the UsedOnComputerName entry is set to one of the servers documented in the issuing process attempt to find a better value.
  if ($_.CommonName -and $_.UsedOnComputerName -in 'EUWATSRV21', 'EUIXESRV21') {
    # Clear the current value, it's pretty meaningless and may just confuse
    $_.UsedOnComputerName = $null
  
    $DnsAnyResponse = Get-KSDns $_.CommonName
    if (-not $DnsAnyResponse -and $_.CommonName -notmatch '\.') {
      $DnsAnyResponse = Get-KSDns "$($_.CommonName).$($_.RequesterDomain).kworld.kpmg.com"
    }
    
    if ($? -and $DnsAnyResponse.Header.RCode -eq 'NoError') {
      if ($DnsAnyResponse.Header.ANCount -eq 1 -and $DnsAnyResponse.Answer[0].RecordType -eq 'CNAME') {
        # Use the CNAME value as the new target. This only accounts for single-hop aliases.
        $_.UsedOnComputerName = $DnsAnyResponse.Answer[0].Hostname -replace '\..+$'

       # Attempt to match this to a record from the Additional section. Captures the IP address of the host.
        $MatchingAdditional = $DnsAnyResponse.Additional | Where-Object { $_.Name -eq $DnsAnyResponse.Answer[0].HostName }
        if ($MatchingAdditional -and $MatchingAdditional.RecordType -eq 'A') {
          if (([Array]$MatchingAdditional).Count -eq 1) {
            $_.BoundInterface = $MatchingAdditional.IPAddress
            
            $_
          } elseif ($MatchingAdditional) {
            $ExistingRecord = $_
            $MatchingAdditional | ForEach-Object {
              $NewRecord = $ExistingRecord | Select-Object *
              $NewRecord.BoundInterface = $_
              
              $NewRecord
            }
          } else {
            $_
          }
        } else {
          $_
        }
        $MatchingAdditional = $null
      } else {
        $IPAddress = $DnsAnyResponse.Answer | Where-Object { $_.RecordType -eq 'A' } | Select-Object -ExpandProperty IPAddress
        if (([Array]$IPAddress).Count -gt 1) {
          $ExistingRecord = $_
          $IPAddress | ForEach-Object {
            $NewRecord = $ExistingRecord | Select-Object *
            $NewRecord.BoundInterface = $_
              
            $NewRecord
          }
        } elseif ($IPAddress) {
          $_.BoundInterface = $IPAddress
          
          $_
        } else {
          $_
        }
      }
    } else {
      $_
    }
  } else {
    $_
  }
} | ForEach-Object {
  if (-not $_.UsedOnComputerName -and $_.BoundInterface) {
    # PTR lookup
    $DnsPtrResponse = Get-KSDns $_.BoundInterface
    if ($? -and $DnsPtrResponse.Header.RCode -eq 'NoError' -and $DnsPtrResponse.Answer[0].HostName -notmatch "^$($_.CommonName -replace '\.', '\.')") {
      $_.UsedOnComputerName = $DnsPtrResponse.Answer[0].Hostname -replace '\..+$'
    }
  }
  
  $_
} | Export-Csv PKI-AllExpiringCertificates-Dns.csv -NoTypeInformation

# Third pass: Update UsedOnComputerName based on the network adapter information in the asset database
#   Run time:     Fast
#   Execute when: Every time a new merged file is generated
Import-Csv PKI-AllExpiringCertificates-Dns.csv | ForEach-Object {
  if (-not $_.UsedOnComputerName -and $_.BoundInterface) {
    if ($CMDBIPAddresses.Contains([IPAddress]$_.BoundInterface)) {
      $_.UsedOnComputerName =  $CMDBIPAddresses[([IPAddress]$_.BoundInterface)]
    }
  }
  
  $_
} | Export-Csv PKI-AllExpiringCertificates-CMDBNIC.csv -NoTypeInformation

# Forth pass: Add in a bit of information from SCVMM.
#   Run time:     Fast
#   Execute when: Every time a new merged file is generated
Import-Csv PKI-AllExpiringCertificates-CMDBNIC.csv | ForEach-Object {
  if ($VirtualMachines.Contains($_.UsedOnComputerName)) {
    $_.ServiceName = $VirtualMachines[$_.UsedOnComputerName].'Service Name'
    $_.BusinessFunction = $VirtualMachines[$_.UsedOnComputerName].'Business Function'
    $_.ServiceOwner = $VirtualMachines[$_.UsedOnComputerName].'Service Owner'
    $_.ServerRole = $VirtualMachines[$_.UsedOnComputerName].'Server Role'
  }
  
  $_
} | Export-Csv PKI-AllExpiringCertificates-SCVMM.csv -NoTypeInformation

# Convert it to Excel
Import-Csv PKI-AllExpiringCertificates-SCVMM.csv | Export-KSExcelWorksheet "PKI-AllExpiringCertificates.xlsx"

