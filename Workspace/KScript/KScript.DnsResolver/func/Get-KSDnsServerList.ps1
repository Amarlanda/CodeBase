function Get-KSDnsServerList {
  # .SYNOPSIS
  #   Gets a list of network interfaces and attempts to return a list of DNS server IP addresses.
  # .DESCRIPTION
  #   Get-KSDnsServerList uses System.Net.NetworkInformation to return a list of operational ethernet or wireless interfaces. IP properties are returned, and an attempt to return a list of DNS server addresses is made. If successful, the DNS server list is returned.
  # .OUTPUTS
  #   System.Net.IPAddress[]
  # .EXAMPLE
  #   Get-KSDnsServerList
  # .EXAMPLE
  #   Get-KSDnsServerList -IPv6
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #   Module: Indented.Common
  #
  #   (c) 2008-2014 Chris Dent.
  #
  #   Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, 
  #   provided that the above copyright notice and this permission notice appear in all copies.
  #
  #   THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED 
  #   WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR 
  #   CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF 
  #   CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.  
  #
  #   Change log:
  #     13/01/2015 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [Switch]$IPv6
  )

  if ($IPv6) {
    $AddressFamily = [Net.Sockets.AddressFamily]::InterNetworkv6
  } else {
    $AddressFamily = [Net.Sockets.AddressFamily]::InterNetwork
  }
  
  if ([Net.NetworkInformation.NetworkInterface]::GetIsNetworkAvailable()) {
    [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() |
      Where-Object { $_.OperationalStatus -eq 'Up' -and $_.NetworkInterfaceType -match 'Ethernet|Wireless' } |
      ForEach-Object { $_.GetIPProperties() } |
      Select-Object -ExpandProperty DnsAddresses -Unique |
      Where-Object AddressFamily -eq $AddressFamily
  }
}

