function ReadKSDnsDSRecord {
  # .SYNOPSIS
  #   Reads properties for an DS record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    KEYTAG                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       ALGORITHM       |      DIGESTTYPE       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    DIGEST                     /
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
  #   KScript.DnsResolver.Message.ResourceRecord.DS
  # .LINK
  #   http://www.ietf.org/rfc/rfc3658.txt
  #   http://www.ietf.org/rfc/rfc4034.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.DS")
  
  # Property: KeyTag
  $ResourceRecord | Add-Member KeyTag -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
  # Property: DigestType
  $ResourceRecord | Add-Member DigestType -MemberType NoteProperty -Value ([KScript.DnsResolver.DigestType]$BinaryReader.ReadByte())
  # Property: Digest
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - 4)
  $HexString = ConvertTo-KSString $Bytes -Hexadecimal
  $ResourceRecord | Add-Member Digest -MemberType NoteProperty -Value $HexString

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} {3}",
      $this.KeyTag.ToString(),
      ([Byte]$this.Algorithm).ToString(),
      ([Byte]$this.DigestType).ToString(),
      $this.Digest)
  }
  
  return $ResourceRecord
}

