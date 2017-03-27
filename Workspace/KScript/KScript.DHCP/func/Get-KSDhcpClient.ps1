function Get-KSDhcpClient {
  # .SYNOPSIS
  #   Get clients from the specified scope from a DHCP server.
  # .DESCRIPTION
  #   Get details of clients within a scope from a DHCP server using the DHCP API.
  # .PARAMETER ScopeAddress
  #   The subnet address of a scope. Wildcards are not supported.
  # .PARAMETER ComputerName
  #   The DHCP server to query.
  # .EXAMPLE
  #   Get-KSDhcpClient -ScopeAddress 10.0.0.0
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     08/01/2015 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('SubnetAddress')]
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
      
    [KScript.Dhcp.DhcpInformation]::GetSubnetClients($ComputerName, $ScopeAddress)
  }
}