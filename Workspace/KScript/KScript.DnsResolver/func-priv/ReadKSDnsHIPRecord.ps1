function ReadKSDnsHIPRecord {
  # .SYNOPSIS
  #   Reads properties for an HIP record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |      HIT LENGTH       |     PK ALGORITHM      |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |               PUBLIC KEY LENGTH               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                      HIT                      /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   PUBLIC KEY                  /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /              RENDEZVOUS SERVERS               /
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
  #   KScript.DnsResolver.Message.ResourceRecord.HIP
  # .LINK
  #   http://www.ietf.org/rfc/rfc5205.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.HIP")

  # Property: HITLength
  $ResourceRecord | Add-Member HIPLength -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.IPSECAlgorithm]$BinaryReader.ReadByte())
  # Property: PublicKeyLength
  $ResourceRecord | Add-Member PublicKeyLength -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: HIT
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.HITLength)
  $HexString = ConvertTo-KSString $Bytes -Hexadecimal
  $ResourceRecord | Add-Member HIT -MemberType NoteProperty -Value $HexString
  # Property: PublicKey
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.PublicKeyLength)
  $Base64String = ConvertTo-KSString $Bytes -Base64
  $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String  
  # Property: RendezvousServers - A container for individual servers
  $ResourceRecord | Add-Member RendezvousServers -MemberType NoteProperty -Value @()
  
  # RecordData handling - a counter to decrement
  $RecordDataLength = $ResourceRecord.RecordDataLength
  if ($RecordDataLength -gt 0) {
    do {
      $BinaryReader.SetMarker()

      $ResourceRecord.RendezvousServers += (ReadDnsDomainName $BinaryReader)
    
      $RecordDataLength = $RecordDataLength - $BinaryReader.BytesFromMarker
    } until ($RecordDataLength -eq 0)
  }
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("( {0} {1}`n" +
                     "    {2}`n" +
                     "    {3} )",
      ([Byte]$this.Algorithm).ToString(),
      $this.HIT,
      $this.PublicKey,
      ($this.RendezvousServers -join "`n"))
  }
  
  return $ResourceRecord
}

