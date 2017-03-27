function Get-KSDhcpScope {
  # .SYNOPSIS
  #   Get configured scopes from a DHCP server.
  # .DESCRIPTION
  #   Get details of the configured scopes from a DHCP server using the DHCP API.
  # .PARAMETER ScopeAddress
  #   Retrieve details of a single scope. Wildcards are not supported.
  # .PARAMETER ComputerName
  #   The DHCP server to query.
  # .EXAMPLE
  #   Get-KSDhcpScope
  # .EXAMPLE
  #   Get-KSDhcpScope 10.0.0.0
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     08/01/2015 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [IPAddress]$ScopeAddress,
  
    [ValidateNotNullOrEmpty()]
    [String]$ComputerName = $env:ComputerName
  )        

  process {
    $IPAddress = [IPAddress]0
    if (-not [IPAddress]::TryParse($ComputerName, [Ref]$IPAddress)) {
      $DnsLookup = [Net.Dns]::GetHostEntry($ComputerName) |
        Select-Object -ExpandProperty AddressList |
        Where-Object AddressFamily -eq InterNetwork |
        Select-Object -First 1
        
      if (-not $DnsLookup) {
        # Thow a terminating error
      } else {
        $ComputerName = $DnsLookup
      }
    }
      
    if ($psboundparameters.ContainsKey("ScopeAddress")) {
      [KScript.Dhcp.DhcpInformation]::GetSubnet($ComputerName, $ScopeAddress)
    } else {
      [KScript.Dhcp.DhcpInformation]::GetSubnets($ComputerName)
    }
  }
}