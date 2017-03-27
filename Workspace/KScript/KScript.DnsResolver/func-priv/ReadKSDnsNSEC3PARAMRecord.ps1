function ReadKSDnsNSEC3PARAMRecord {
  # .SYNOPSIS
  #   Reads properties for an NSEC3PARAM record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       HASH ALG        |         FLAGS         |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   ITERATIONS                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       SALT LEN        |                       /
  #    +--+--+--+--+--+--+--+--+                       /
  #    /                      SALT                     /
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
  #   KScript.DnsResolver.Message.ResourceRecord.NSEC3PARAM
  # .LINK
  #   http://www.ietf.org/rfc/rfc5155.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.NSEC3PARAM")

  # Property: HashAlgorithm
  $ResourceRecord | Add-Member HashAlgorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.NSEC3HashAlgorithm]$BinaryReader.ReadByte())
  # Property: Flags
  $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Iterations
  $ResourceRecord | Add-Member Iterations -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: SaltLength
  $ResourceRecord | Add-Member SaltLength -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Salt
  $HexString = ""
  if ($ResouceRecord.SaltLength -gt 0) {
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.SaltLength)
    $HexString = ConvertTo-KSString $Bytes -Hexadecimal
  }
  $ResourceRecord | Add-Member Salt -MemberType NoteProperty -Value $HexString
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} {3}",
      ([Byte]$this.HashAlgorithm).ToString(),
      $this.Flags.ToString(),
      $this.Iterations.ToString(),
      $this.Salt)
  }
  
  return $ResourceRecord
}

