function ReadKSDnsDNSKEYRecord {
  # .SYNOPSIS
  #   Reads properties for an DNSKEY record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     FLAGS                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |        PROTOCOL       |       ALGORITHM       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  PUBLIC KEY                   /
  #    /                                               /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  #   The flags field takes the following format, discussed in RFC 4034 2.1.1:
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    | Z|                    | S|
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  #   Where Z represents the ZoneKey bit, and S the SecureEntryPoint bit.
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
  #   KScript.DnsResolver.Message.ResourceRecord.DNSKEY
  # .LINK
  #   http://www.ietf.org/rfc/rfc3755.txt
  #   http://www.ietf.org/rfc/rfc4034.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.DNSKEY")

  # Property: Flags
  $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value ($BinaryReader.ReadBEUInt16())
  # Property: ZoneKey (bit 7 of Flags)
  $ResourceRecord | Add-Member ZoneKey -MemberType ScriptProperty -Value {
    [Boolean]($this.Flags -band 0x0100)
  }
  # Property: SecureEntryPoint (bit 15 of Flags)
  $ResourceRecord | Add-Member SecureEntryPoint -MemberType ScriptProperty -Value {
    [Boolean]($this.Flags -band 0x0001)
  }
  # Property: Protocol
  $ResourceRecord | Add-Member Protocol -MemberType NoteProperty -Value ([KScript.DnsResolver.KEYProtocol]$BinaryReader.ReadByte())
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
  # Property: PublicKey
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $Base64String = ConvertTo-KSString $Bytes -Base64
  $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} ( {3} )",
      $this.Flags,
      ([Byte]$this.Protocol).ToString(),
      ([Byte]$this.Algorithm).ToString(),
      $this.PublicKey)
  }
  
  return $ResourceRecord
}

