function ReadKSDnsSSHFPRecord {
  # .SYNOPSIS
  #   Reads properties for an SSHFP record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       ALGORITHM       |        FPTYPE         |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  FINGERPRINT                  /
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
  #   KScript.DnsResolver.Message.ResourceRecord.SSHFP
  # .LINK
  #   http://www.ietf.org/rfc/rfc4255.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.SSHFP")

  # Property: Algorithm
  $ResourceRecord | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.SSHAlgorithm]$BinaryReader.ReadByte())
  # Property: FPType
  $ResourceRecord | Add-Member FPType -MemberType NoteProperty -Value ([KScript.DnsResolver.SSHFPType]$BinaryReader.ReadByte())
  # Property: Fingerprint
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - 2)
  $HexString = ConvertTo-KSString $Bytes -Hexadecimal
  $ResourceRecord | Add-Member Fingerprint -MemberType NoteProperty -Value $HexString

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2}",
      ([Byte]$this.Algorithm).ToString(),
      ([Byte]$this.FPType).ToString(),
      $this.Fingerprint)
  }
  
  return $ResourceRecord
}

