function Send-KSBytes {
  # .SYNOPSIS
  #   Sends bytes using a TCP or UDP socket.
  # .DESCRIPTION
  #   Send-KSBytes is used to send outbound TCP or UDP packets as a server responding to a cilent, or as a client sending to a server.
  # .PARAMETER Broadcast
  #   Sets the RemoteIPAddress to the undirected broadcast address.
  # .PARAMETER RemoteIPAddress
  #   If the Protocol Type is UDP a remote IP address must be defined. Directed or undirected broadcast addresses may be used if EnableBroadcast has been set on the socket.
  # .PARAMETER Socket
  #   A socket created using New-KSSocket. If the ProtocolType is TCP the socket must be connected first.
  # .INPUTS
  #   System.Net.Sockets.Socket
  #   System.UInt32
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket
  #   C:\PS>Connect-KSSocket $Socket -RemoteIPAddress 10.0.0.1 -RemotePort 25
  #   C:\PS>Send-KSBytes $Socket -Data 0
  # .EXAMPLE
  #   C:\PS>$Socket = New-KSSocket -ProtocolType Udp -EnableBroadcast
  #   C:\PS>Send-KSBytes $Socket -Data 0
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
  
  [CmdLetBinding(DefaultParameterSetName = 'DirectedTcpSend')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [Net.Sockets.Socket]$Socket,

    [Parameter(Mandatory = $true, ParameterSetName = 'DirectedUdpSend')]
    [IPAddress]$RemoteIPAddress,

    [Parameter(Mandatory = $true, ParameterSetName = 'BroadcastUdpSend')]
    [Switch]$Broadcast,
    
    [Parameter(Mandatory = $true, ParameterSetname = 'DirectedUdpSend')]
    [Parameter(Mandatory = $true, ParameterSetName = 'BroadcastUdpSend')]
    [UInt16]$RemotePort,
   
    [Parameter(Mandatory = $true)]
    [Byte[]]$Data
  )
  
  # Broadcast parameter set checking
  if ($pscmdlet.ParameterSetName -eq 'BroadcastUdpSend') {
    # IPv6 error checking
    if ($Socket.AddressFamily -eq [Net.Sockets.AddressFamily]::InterNetworkv6) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "EnableBroadcast cannot be set for IPv6 sockets."),
        "ArgumentException",
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $Socket)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
    
    # TCP socket error checking
    if (-not $Socket.ProtocolType) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "EnableBroadcast cannot be set for TCP sockets."),
        "ArgumentException",
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $Socket)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
    
    # Broadcast flag checking
    if (-not $Socket.EnableBroadcast) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object InvalidOperationException "EnableBroadcast is not set on the socket."),
        "InvalidOperation",
        [Management.Automation.ErrorCategory]::InvalidOperation,
        $Socket)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }

    $RemoteIPAddress = [IPAddress]::Broadcast
  }

  switch ($Socket.ProtocolType) {
    ([Net.Sockets.ProtocolType]::Tcp) {
    
      $Socket.Send($Data) | Out-Null

      break
    }
    ([Net.Sockets.ProtocolType]::Udp) {
      $RemoteEndPoint = [Net.EndPoint](New-Object Net.IPEndPoint($RemoteIPAddress, $RemotePort))
      
      $Socket.SendTo($Data, $RemoteEndPoint) | Out-Null

      break
    }
  }
}  