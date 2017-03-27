function ReadKSDnsTKEYRecord {
  # .SYNOPSIS
  #   Reads properties for an TKEY record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   ALGORITHM                   /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   INCEPTION                   |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   EXPIRATION                  |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     MODE                      |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     ERROR                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    KEYSIZE                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    KEYDATA                    /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   OTHERSIZE                   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   OTHERDATA                   /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-KSBinaryReader (KScript.NetworkTools) containing a byte array representing a DNS resource record.
  # .PARAMETER ResourceRecord
  #   An KScript.DnsResolver.Message.ResourceRecord object created by ReadKSDnsResourceRecord.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-KSBinaryReader (KScript.NetworkTools)
  # .OUTPUTS
  #   KScript.DnsResolver.Message.ResourceRecord.TKEY
  # .LINK
  #   http://www.ietf.org/rfc/rfc2930.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.TKEY")
  
  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)
  # Property: Inception
  $ResourceRecord | Add-Member Inception -MemberType NoteProperty -Value ((Get-Date "01/01/1970").AddSeconds($BinaryReader.ReadBEUInt32()))
  # Property: Expiration
  $ResourceRecord | Add-Member Expiration -MemberType NoteProperty -Value ((Get-Date "01/01/1970").AddSeconds($BinaryReader.ReadBEUInt32()))
  # Property: Mode
  $ResourceRecord | Add-Member Expiration -MemberType NoteProperty -Value ([KScript.DnsResolver.TKEYMode]$BinaryReader.ReadBEUInt16())
  # Property: Error
  $ResourceRecord | Add-Member Expiration -MemberType NoteProperty -Value ([KScript.DnsResolver.RCode]$BinaryReader.ReadBEUInt16())
  # Property: KeySize
  $ResourceRecord | Add-Member KeySize -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: KeyData
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.KeySize)
  $HexString = ConvertTo-KSString $Bytes -Hexadecimal
  $ResourceRecord | Add-Member KeyData -MemberType NoteProperty -Value $HexString
  
  if ($ResourceRecord.OtherSize -gt 0) {
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.OtherSize)
    $HexString = ConvertTo-KSString $Bytes -Hexadecimal
  }

  # Property: OtherData
  $ResourceRecord | Add-Member KeyData -MemberType NoteProperty -Value $HexString
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} {3} {4}",
      $this.Algorithm,
      $this.Inception,
      $this.Expiration,
      $this.Mode,
      $this.KeyData)
  }
  
  return $ResourceRecord
}

