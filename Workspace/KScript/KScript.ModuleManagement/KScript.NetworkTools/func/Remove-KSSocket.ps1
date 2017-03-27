function Remove-KSSocket {
  # .SYNOPSIS
  #   Removes a socket, releasing all resources.
  # .DESCRIPTION
  #   A socket may be removed using Remove-KSSocket if it is no longer required.
  # .PARAMETER Socket
  #   A socket created using New-KSSocket.
  # .INPUTS
  #   System.Net.Sockets.Socket
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket
  #   C:\PS>$Socket | Connect-KSSocket -RemoteIPAddress 10.0.0.2 -RemotePort 25
  #   C:\PS>$Socket | Disconnect-KSSocket
  #   C:\PS>$Socket | Remove-KSSocket
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
    [Net.Sockets.Socket]$Socket
  )

  process {
    # Close the socket
    $Socket.Close()
  }
}