function ReadKSDnsIPSECKEYRecord {
  # .SYNOPSIS
  #   Reads properties for an IPSECKEY record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |      PRECEDENCE       |      GATEWAYTYPE      |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       ALGORITHM       |                       /
  #    +--+--+--+--+--+--+--+--+                       /
  #    /                    GATEWAY                    /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   PUBLICKEY                   /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-KSBinaryReader (Indented.Common) containing a byte array representing a DNS resource record.
  # .PARAMETER ResourceRecord
  #   An KScript.DnsResolver.Message.ResourceRecord object created by ReadKSDnsResourceRecord.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-KSBinaryReader (Indented.Common)
  # .OUTPUTS
  #   KScript.DnsResolver.Message.ResourceRecord.IPSECKEY
  # .LINK
  #   http://www.ietf.org/rfc/rfc4025.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.IPSECKEY")
  
  # Property: Precedence
  $ResourceRecord | Add-Member Precedence -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: GatewayType
  $ResourceRecord | Add-Member GatewayType -MemberType NoteProperty -Value ([KScript.DnsResolver.IPSECGatewayType]$BinaryReader.ReadByte())
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.IPSECAlgorithm]$BinaryReader.ReadByte())
  
  switch ($ResourceRecord.GatewayType) {
    ([KScript.DnsResolver.IPSECGatewayType]::NoGateway) {
      $Gateway = ""
      
      break
    }
    ([KScript.DnsResolver.IPSECGatewayType]::IPv4) {
      $Gateway = $BinaryReader.ReadIPv4Address()
      
      break
    }
    ([KScript.DnsResolver.IPSECGatewayType]::IPv6) {
      $Gateway = $BinaryReader.ReadIPv6Address()
      
      break
    }
    ([KScript.DnsResolver.IPSECGatewayType]::DomainName) {
      $Gateway = ConvertToKSDnsDomainName $BinaryReader
    
      break
    }
  }
  
  # Property: Gateway
  $ResourceRecord | Add-Member Gateway -MemberType NoteProperty -Value $Gateway
  # Property: PublicKey
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $Base64String = ConvertTo-KSString $Bytes -Base64
  $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format(" ( {0} {1} {2}`n" +
                     "    {3}`n" +
                     "    {4} )",
      $this.Precedence.ToString(),
      ([Byte]$this.GatewayType).ToString(),
      ([Byte]$this.Algorithm).ToString(),
      $this.Gateway,
      $this.PublicKey)
  }
  
  return $ResourceRecord
}

