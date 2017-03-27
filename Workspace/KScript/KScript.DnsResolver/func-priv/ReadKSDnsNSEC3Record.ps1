function ReadKSDnsNSEC3Record {
  # .SYNOPSIS
  #   Reads properties for an NSEC3 record from a byte stream.
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
  #    |       HASH LEN        |                       /
  #    +--+--+--+--+--+--+--+--+                       /
  #    /                      HASH                     /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                                               /
  #    /                   <BIT MAP>                   /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
  #
  #   The flags field takes the following format, discussed in RFC 5155 3.2:
  #
  #      0  1  2  3  4  5  6  7 
  #    +--+--+--+--+--+--+--+--+
  #    |                    |O |
  #    +--+--+--+--+--+--+--+--+
  #
  #   Where O, bit 7, represents the Opt-Out Flag.
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
  #   KScript.DnsResolver.Message.ResourceRecord.NSEC3
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

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.NSEC3")

  # Property: HashAlgorithm
  $ResourceRecord | Add-Member HashAlgorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.NSEC3HashAlgorithm]$BinaryReader.ReadByte())
  # Property: Flags
  $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: OptOut
  $ResourceRecord | Add-Member OptOut -MemberType ScriptProperty -Value {
    [Boolean]($this.Flags -band [KScript.DnsResolver.NSEC3Flags]::OutOut)
  }
  # Property: Iterations
  $ResourceRecord | Add-Member Iterations -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: SaltLength
  $ResourceRecord | Add-Member SaltLength -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Salt
  if ($ResourceRecord.SaltLength -gt 0) {
    $Bytes = $BinaryReader.ReadBytes($ResourceRecord.SaltLength)
    $Base64String = ConvertTo-KSString $Bytes -Base64
  }
  $ResourceRecord | Add-Member Salt -MemberType NoteProperty -Value $Base64String
  # Property: HashLength
  $ResourceRecord | Add-Member HashLength -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Hash
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.HashLength)
  $Base64String = ConvertTo-KSString $Bytes -Base64
  $ResourceRecord | Add-Member Hash -MemberType NoteProperty -Value $Base64String
  # Property: RRTypeBitMap
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $BinaryString = ConvertTo-KSString $Bytes -Binary
  $ResourceRecord | Add-Member RRTypeBitMap -MemberType NoteProperty -Value $BinaryString
  # Property: RRTypes
  $ResourceRecord | Add-Member RRTypes -MemberType ScriptProperty -Value {
    $RRTypes = @()
    [Enum]::GetNames([KScript.DnsResolver.RecordType]) |
      Where-Object { [UInt16][KScript.DnsResolver.RecordType]::$_ -lt $BinaryString.Length -and 
        $BinaryString[([UInt16][KScript.DnsResolver.RecordType]::$_)] -eq '1' } |
      ForEach-Object {
        $RRTypes += [KScript.DnsResolver.RecordType]::$_
      }
    $RRTypes
  }
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} {3} (`n" +
                     "{4} {5} )",
      ([Byte]$this.HashAlgorithm).ToString(),
      $this.Flags.ToString(),
      $this.Iterations.ToString(),
      $this.Salt,
      $this.Hash,
      "$($this.RRTypes)")
  }
  
  return $ResourceRecord
}

