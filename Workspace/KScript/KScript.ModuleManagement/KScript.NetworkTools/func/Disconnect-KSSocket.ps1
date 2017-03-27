function Disconnect-KSSocket {
  # .SYNOPSIS
  #   Disconnect a connected TCP socket.
  # .DESCRIPTION
  #   A TCP socket which has been connected using Connect-Socket may be disconnected using this CmdLet.
  # .PARAMETER Shutdown
  #   By default, Disconnect-Socket attempts to shutdown the connection before disconnecting. This behaviour can be overridden by setting this parameter to False.
  # .PARAMETER Socket
  #   A socket created using New-Socket and connected using Connect-Socket.
  # .INPUTS
  #   System.Net.Sockets.Socket
  # .OUTPUTS
  #   None
  #
  #   Disconnect-Socket performs an operation on an existing socket created using New-Socket.
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket
  #   C:\PS>$Socket | Connect-KSSocket -RemoteIPAddress 10.0.0.2 -RemotePort 25
  #   C:\PS>$Socket | Disconnect-KSSocket
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

    [Boolean]$Shutdown = $true
  )

  process {
    if ($Socket.ProtocolType -ne [Net.Sockets.ProtocolType]::Tcp) {
      Write-Error "Disconnect-KSSocket: The protocol type must be TCP to use Disconnect-Socket." -Category InvalidOperation
      return
    }

    if (-not $Socket.Connected) {
      Write-Warning "Disconnect-KSSocket: The socket is not connected. No action taken."
    } else {
      Write-Verbose "Disconnect-KSSocket: Disconnected socket from $($Socket.RemoteEndPoint)."

      if ($Shutdown) {
        $Socket.Shutdown([Net.Sockets.SocketShutdown]::Both)
      }

      # Disconnect the socket and allow reuse.
      $Socket.Disconnect($true)
    }
  }
}