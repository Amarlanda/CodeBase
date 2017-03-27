function ReadKSDnsSINKRecord {
  # .SYNOPSIS
  #   Reads properties for an SINK record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |        CODING         |       SUBCODING       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                     DATA                      /
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
  #   KScript.DnsResolver.Message.ResourceRecord.DNAME
  # .LINK
  #   http://tools.ietf.org/id/draft-eastlake-kitchen-sink-02.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.SINK")

  # Property: Coding
  $ResourceRecord | Add-Member Coding -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Subcoding
  $ResourceRecord | Add-Member Subcoding -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: Data
  $Length = $ResourceRecord.RecordDataLength - 2
  $ResourceRecord | Add-Member Data -MemberType NoteProperty -Value $BinaryReader.ReadBytes($Length)
  
  return $ResourceRecord
}

