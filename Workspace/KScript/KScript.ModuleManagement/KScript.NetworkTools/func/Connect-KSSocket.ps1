function Connect-KSSocket {
  # .SYNOPSIS
  #   Connect a TCP socket to a remote IP address and port.
  # .DESCRIPTION
  #   If a TCP socket is being used as a network client it must first connect to a server before Send-Bytes and Receive-Bytes can be used.
  # .PARAMETER RemoteIPAddress
  #   The remote IP address to connect to.
  # .PARAMETER RemotePort
  #   The remote port to connect to.
  # .PARAMETER Socket
  #   A socket created using New-Socket.
  # .INPUTS
  #   System.Net.IPAddress
  #   System.Net.Sockets.Socket
  #   System.UInt16
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket
  #   C:\PS>Connect-KSSocket $Socket -RemoteIPAddress 10.0.0.2 -RemotePort 25
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #   Module: Indented.Common
  #
  #   (c) 2008-2015 Chris Dent.
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
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [Net.Sockets.Socket]$Socket,
    
    [Parameter(Mandatory = $true)]
    [Alias('IPAddress')]
    [IPAddress]$RemoteIPAddress,

    [Parameter(Mandatory = $true)]
    [Alias('Port')]
    [UInt16]$RemotePort
  )

  process {
    if ($Socket.ProtocolType -ne [Net.Sockets.ProtocolType]::Tcp) {
      Write-Error "Connect-KSSocket: The protocol type must be TCP to use Connect-KSSocket." -Category InvalidOperation
      return
    }

    $RemoteEndPoint = [Net.EndPoint](New-Object Net.IPEndPoint($RemoteIPAddress, $RemotePort))

    if ($Socket.Connected) {
      Write-Warning "Connect-KSSocket: The socket is connected to $($Socket.RemoteEndPoint). No action taken."
    } else {
      $Socket.Connect($RemoteEndPoint)
    }
  }
}