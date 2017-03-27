function ReadKSDnsPXRecord {
  # .SYNOPSIS
  #   Reads properties for an PX record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  PREFERENCE                   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   MAP822                      /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   MAPX400                     /
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
  #   KScript.DnsResolver.Message.ResourceRecord.PX
  # .LINK
  #   http://www.ietf.org/rfc/rfc2163.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.PX")
  
  # Property: Preference
  $ResourceRecord | Add-Member Preference -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: MAP822
  $ResourceRecord | Add-Member MAP822 -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)
  # Property: MAPX400
  $ResourceRecord | Add-Member MAPX400 -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2}",
      $this.Preference.ToString().PadRight(5, ' '),
      $this.MAP822,
      $this.MAPX400)
  }
  
  return $ResourceRecord
}

