function ReadKSDnsKEYRecord {
  # .SYNOPSIS
  #   Reads properties for an KEY record from a byte stream.
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
  #   The flags field takes the following format, discussed in RFC 2535 3.1.2:
  #
  #      0   1   2   3   4   5   6   7   8   9   0   1   2   3   4   5
  #    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
  #    |  A/C  | Z | XT| Z | Z | NAMTYP| Z | Z | Z | Z |      SIG      |
  #    +---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+---+
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
  #   KScript.DnsResolver.Message.ResourceRecord.KEY
  # .LINK
  #   http://www.ietf.org/rfc/rfc2535.txt
  #   http://www.ietf.org/rfc/rfc2931.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.KEY")

  # Property: Flags
  $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value ($BinaryReader.ReadBEUInt16())
  # Property: Authentication/Confidentiality (bit 0 and 1 of Flags)
  $ResourceRecord | Add-Member AuthenticationConfidentiality -MemberType ScriptProperty -Value {
    [KScript.DnsResolver.KEYAC]([Byte]($this.Flags -shr 14))
  }
  # Property: Flags extension (bit 3)
  if (($Flags -band 0x1000) -eq 0x1000) {
    $ResourceRecord | Add-Member FlagsExtension -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  }
  # Property: NameType (bit 6 and 7)
  $ResourceRecord | Add-Member NameType -MemberType ScriptProperty -Value {
    [KScript.DnsResolver.KEYNameType]([Byte](($Flags -band 0x0300) -shr 9))
  }
  # Property: SignatoryField (bit 12 and 15)
  $ResourceRecord | Add-Member SignatoryField -MemberType ScriptProperty -Value {
    [Boolean]($this.Flags -band 0x000F)
  }
  # Property: Protocol
  $ResourceRecord | Add-Member Protocol -MemberType NoteProperty -Value ([KScript.DnsResolver.KEYProtocol]$BinaryReader.ReadByte())
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
  
  if ($ResourceRecord.AuthenticationConfidentiality -ne [KScript.DnsResolver.KEYAC]::NoKey) {
    # Property: PublicKey
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
    $Base64String = ConvertTo-KSString $Bytes -Base64
    $ResourceRecord | Add-Member PublicKey -MemberType NoteProperty -Value $Base64String
  }

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

