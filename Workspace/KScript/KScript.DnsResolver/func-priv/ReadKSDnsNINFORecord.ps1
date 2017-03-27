function ReadKSDnsNINFORecord {
  # .SYNOPSIS
  #   Reads properties for an NINFO record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Present for legacy support; the NINFO record is marked as obsolete in favour of MX.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    ZS-DATA                    /
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
  #   KScript.DnsResolver.Message.ResourceRecord.NINFO
  # .LINK
  #   http://tools.ietf.org/html/draft-lewis-dns-undocumented-types-01
  #   http://tools.ietf.org/html/draft-reid-dnsext-zs-01
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.NINFO")

  # Property: RendezvousServers - A container for individual servers
  $ResourceRecord | Add-Member ZSData -MemberType NoteProperty -Value @()
  
  # RecordData handling - a counter to decrement
  $RecordDataLength = $ResourceRecord.RecordDataLength
  if ($RecordDataLength -gt 0) {
    do {
      $BinaryReader.SetMarker()

      $ResourceRecord.ZSData += (ReadKSDnsCharacterString $BinaryReader)
    
      $RecordDataLength = $RecordDataLength - $BinaryReader.BytesFromMarker
    } until ($RecordDataLength -eq 0)
  }
    
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    "$($this.ZSData)"
  }
  
  return $ResourceRecord
}


