function Receive-KSBytes {
  # .SYNOPSIS
  #   Receive bytes using a TCP or UDP socket.
  # .DESCRIPTION
  #   Receive-KSBytes is used to accept inbound TCP or UDP packets as a client exepcting a response from a server, or as a server waiting for incoming connections.
  #
  #   Receive-KSBytes will listen for bytes sent to broadcast addresses provided the socket has been created using EnableBroadcast.
  # .PARAMETER BufferSize
  #   The maximum buffer size used for each receive operation.
  # .PARAMETER Socket
  #   A socket created using New-KSSocket. If the ProtocolType is TCP the socket must be connected first.
  # .INPUTS
  #   System.Net.Sockets.Socket
  #   System.UInt32
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket
  #   C:\PS>Connect-KSSocket $Socket -RemoteIPAddress 10.0.0.1 -RemotePort 25
  #   C:\PS>$Bytes = Receive-KSBytes $Socket
  #   C:\PS>$Bytes | ConvertTo-KSString
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket -ProtocolType Udp -EnableBroadcast
  #   C:\PS>$Socket | Receive-KSBytes
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
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [Net.Sockets.Socket]$Socket,
    
    [UInt32]$BufferSize = 1024
  )

  $Buffer = New-Object Byte[] $BufferSize 

  switch ($Socket.ProtocolType) {
    ([Net.Sockets.ProtocolType]::Tcp) {
      $BytesReceived = $null; $BytesReceived = $Socket.Receive($Buffer)
      Write-Verbose "Receive-KSBytes: Received $BytesReceived from $($Socket.RemoteEndPoint): Connection State: $($Socket.Connected)"

      $Response = New-Object PsObject -Property ([Ordered]@{
        BytesReceived  = $BytesReceived;
        Data           = $Buffer[0..$($BytesReceived - 1)];
        RemoteEndPoint = $Socket.RemoteEndPoint | Select-Object *;
      })
      break
    }
    ([Net.Sockets.ProtocolType]::Udp) {
      # Create an IPEndPoint to use as a reference object
      if ($Socket.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetwork) {
        $RemoteEndPoint = [Net.EndPoint](New-Object Net.IPEndPoint([IPAddress]::Any, 0))
      } elseif ($Socket.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkv6) {
        $RemoteEndPoint = [Net.EndPoint](New-Object Net.IPEndPoint([IPAddress]::IPv6Any, 0))
      }
      
      $BytesReceived = $null; $BytesReceived = $Socket.ReceiveFrom($Buffer, [Ref]$RemoteEndPoint)
      Write-Verbose "Receive-KSBytes: Received $BytesReceived from $($RemoteEndPoint.Address.IPAddressToString)"

      $Response = New-Object PsObject -Property ([Ordered]@{
        BytesReceived  = $BytesReceived;
        Data           = $Buffer[0..$($BytesReceived - 1)];
        RemoteEndPoint = $RemoteEndPoint | Select-Object *;
      })
      break
    }
  }
  if ($Response) {
    $Response.PsObject.TypeNames.Add("KScript.Sockets.SocketResponse")
    return $Response
  }
}