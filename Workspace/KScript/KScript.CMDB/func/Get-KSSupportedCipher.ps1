function Get-KSSupportedCipher {
  # .SYNOPSIS
  #   Get supported ciphers from a remote SSL service.
  # .DESCRIPTION
  #   Get-KSSupportedCipher uses the NMAP tool to enumerate and report on the ciphers supported by a remote service end point.
  #
  #   NMAP must be installed independently for this function to operate.
  #
  #   All IPv6 end-points are ignored. All of the following ports are ignored:
  #
  #     * 53 - DNS (TCP listener)
  #     * 135 - RPC EndPoint Mapper
  #     * 139 - NetBIOS
  #     * 445 - SMB
  #     * 1433 - SQL
  #     * 1434 - SQL
  #     * 3389 - RDP
  #     * 50000 - SQL
  #
  # .PARAMETER ComputerName
  #   The computer name to test. The ComputerName is used if there are no valid IPEndPoints, or the IPEndPoint is bound to any interface.
  # .PARAMETER IgnorePorts
  #   Specific well-known ports are ignored as noted in the CmdLet description.
  # .PARAMETER IPEndPoint
  #   The list of end-points to test.
  # .PARAMETER NmapExe
  #   The full path to the NMAP executable which must be separately installed.
  # .INPUTS
  #   System.String
  #   System.UInt16
  # .OUTPUTS
  #   KScript.NMAP.SupportedCipher
  # .EXAMPLE
  #   Get-KSSupportedCipher -ComputerName SomeHost -IPEndPoint "1.2.3.4:443", "[::]:443", "0.0.0.0:3389"
  #
  #   Port 443 will be scanned using the IP 1.2.3.4, the IPv6 binding will be ignored. Port 3389 will be skipped as it is on the list of ignored ports.
  # .LINKS
  #   http://nmap.org/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     28/10/2014 - Chris Dent - BugFix: Ensure null IPEndPoint values are not processed.
  #     24/10/2014 - Chris Dent - Added alternate end conditions for all while and do loops. Limited concurrent jobs to 10.
  #     23/10/2014 - Chris Dent - Modified to execute nmap on a per-port basis as a job. Added port white-listing for well-known ports.
  #     16/10/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [String]$ComputerName,
  
    [ValidatePattern('^\S+:\d+$')]
    [String[]]$IPEndPoint = @("0.0.0.0:443", "0.0.0.0:8443", "0.0.0.0:1311", "0.0.0.0:2381"),
   
    [Int32[]]$IgnorePorts = @(53, 135, 139, 445, 1433, 1434, 3389, 50000),

    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$NmapExe = 'C:\Program Files (x86)\Nmap\nmap.exe'
  )
  
  begin {
    $IPEndPoint |
      Where-Object { $_ } |
      ForEach-Object {
        $IPEndPointObject = New-Object Net.IPEndPoint([IPAddress]($_ -replace ':\d+$'), ($_ -replace '^.+:'))
        if ($IPEndPointObject.Address.IPAddressToString -notlike '127.0.0.*' -and $IPEndPointObject.AddressFamily -eq 'InterNetwork' -and $IPEndPointObject.Port -notin $IgnorePorts) {
          if ($IPEndPointObject.Address -eq [IPAddress]0) {
            if ([IPAddress]::TryParse($ComputerName, [Ref]$null)) {
              $IPEndPointObject.Address = $ComputerName
              $IPEndPointObject
            } else {
              $DnsRecord = Get-Dns $ComputerName -RecordType A
              if ($DnsRecord.Header.ANCount -ge 1) {
                $IPEndPointObject.Address = $DnsRecord.Answer[0].IPAddress
                $IPEndPointObject
              }
            }
          } else {
            $IPEndPointObject
          }
        }
      } |
      ForEach-Object {
        $InterfaceName = $_.Address
        $Port = $_.Port

        # Wait until a job slot becomes available.
        while ((Get-Job -State Running | Measure-Object).Count -ge 10) {
          Start-Sleep -Seconds 10
        }
        
        Write-Verbose "$($ComputerName): Starting NMAP SSL probe against $_"
        
        Start-Job -ArgumentList $InterfaceName, $Port, $NmapExe -ScriptBlock {
          param(
            $InterfaceName,
            
            $Port,
            
            $NmapExe
          )
        
          & $NMapExe "--host-timeout", "2m", "-n", "--script", """ssl-cert,ssl-enum-ciphers""", "-p", """$($Port -join ',')""", "-sV", "--version-light", $InterfaceName | Out-String
        } | Out-Null
      }
    
    # Allow 5 minutes for the scans to complete (the loop will exit immediately if no jobs are running)
    $StopWatch = New-Object Diagnostics.StopWatch
    $StopWatch.Start()
    do {
      Start-Sleep -Seconds 10
    } until (-not (Get-Job -State Running) -or ($StopWatch.Elapsed.TotalMinutes -ge 5))
    $StopWatch.Stop()
    
    # Forcefully terminate any nmap process which appears to be stuck or is simply taking too long for the purposes of this script.
    Get-Job -State Running | Remove-Job -Force
    
    Get-Job -State Completed |
      Receive-Job |
      ForEach-Object {
        $NMapResponse = $_ -split '\r?\n'
        $Count = $NMapResponse.Count
        
        $InterfaceName = $NMapResponse[2] -replace '^.+report for |[ \t]*$'
        
        for ($i = 0; $i -lt $Count; $i++) {
          if ($NMapResponse[$i] -match '^(?<Port>\d+)/tcp\s+(?<State>\S+)\s+(?<Service>\S+)(?:\s+(?<Version>.+))?$') {
            $Listener = New-Object PSObject -Property ([Ordered]@{
              Port    = $matches.Port
              State   = $matches.State
              Service = $matches.Service
              Version = $matches.Version
            })
            
            $ReadProtocolsAndCiphers = $false

            while ($NMapResponse[$i + 1] -match '^\|' -and $i -lt $Count) {
              if ($NMapResponse[$i] -match '^\|\s*ssl-cert: Subject: commonName=(?<CommonName>.+)$') {
                $Certificate = New-Object PSObject -Property ([Ordered]@{
                  CommonName = $matches.CommonName
                  Issuer     = $NMapResponse[++$i] -replace '^.+='
                  KeyType    = ($NMapResponse[++$i] -replace '^.+: ').ToUpper()
                  KeyLength  = $NMapResponse[++$i] -replace '^.+: '
                  Inception  = (Get-Date ($NMapResponse[++$i] -replace '^.+: '))
                  Expiration = (Get-Date ($NMapResponse[++$i] -replace '^.+: '))
                })
              }
            
              if ($NMapResponse[$i] -match 'least strength: ') {
                $ReadProtocolsAndCiphers = $false
              }

              if ($ReadProtocolsAndCiphers) {
                $Protocol = New-Object PSObject -Property ([Ordered]@{
                  Protocol = ($NMapResponse[$i] -replace '^\|\s*|:').Trim()
                  Ciphers  = @()
                })
                if ($NMapResponse[++$i] -match 'ciphers:') {
                  do {
                    $Protocol.Ciphers += $NMapResponse[++$i] -replace '^\|\s*| - \S+$'
                  } until ($NMapResponse[$i + 1] -match 'compressors:' -or $i -ge $Count)
                  do {
                    $i++
                  } until ($NMapResponse[$i] -match 'NULL' -or $NMapResponse[$i + 1] -match '^\|\s*(SSL|TLS)' -or $i -ge $Count)
                }
                
                New-Object PSObject -Property ([Ordered]@{
                  InterfaceName         = $InterfaceName
                  Port                  = $Listener.Port
                  State                 = $Listener.State
                  Service               = $Listener.Service
                  Version               = $Listener.Version
                  CertificateCommonName = $Certificate.CommonName
                  CertificateIssuer     = $Certificate.Issuer
                  CertificateKeyType    = $Certificate.KeyType
                  CertificateKeyLength  = $Certificate.KeyLength
                  CertificateInception  = $Certificate.Inception
                  CertificateExpiration = $Certificate.Expiration
                  Protocol              = $Protocol.Protocol
                  CipherSet             = $Protocol.Ciphers
                })
                
                $Protocol = $null
              }
              
              if ($NMapResponse[$i] -match '^\|\s*ssl-enum-ciphers:') {
                $ReadProtocolsAndCiphers = $true
              }
              $i++
            }

            $Listener = $null; $Certificate = $null
          }
        }
      }
      
    Get-Job | Remove-Job -Force
  }
}