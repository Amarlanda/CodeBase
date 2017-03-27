function Test-KSTcpPort {
  # .SYNOPSIS
  #   Test a TCP Port using System.Net.Sockets.TcpClient.
  # .DESCRIPTION
  #   Test-TcpPort establishes a TCP connection to the sepecified port then immediately closes the connection, returning whether or not the connection succeeded.
  #       
  #   This function fully opens TCP connections (3-way handshake), it does not half-open connections.
  # .PARAMETER IPAddress
  #   An IP address for the target system.
  # .PARAMETER Port
  #   The port number to connect to (between 1 and 655535).
  # .EXAMPLE
  #   Test-TcpPort 10.0.0.1 3389
  #
  #   Opens a TCP connection to 10.0.0.1 using port 3389.
  # .INPUTS
  #   System.Net.IPAddress
  #   System.UInt16
  # .OUTPUTS
  #   System.Boolean
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
  #     09/01/2015 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IPAddress]$IPAddress,
    
    [Parameter(Mandatory = $true)]
    [UInt16]$Port
  )

  $TcpClient = New-Object Net.Sockets.TcpClient
  try { $TcpClient.Connect($IPAddress, $Port) } catch { }
  if ($?) {
    $TcpClient.Close()
    return $true
  }
  return $false
}