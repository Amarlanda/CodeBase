function ReadKSDnsAFSDBRecord {
  # .SYNOPSIS
  #   Reads properties for an AFSDB record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    SUBTYPE                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    HOSTNAME                   /
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
  #   KScript.DnsResolver.Message.ResourceRecord.AFSDB
  # .LINK
  #   http://www.ietf.org/rfc/rfc1183.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.AFSDB")
  
  $SubType = $BinaryReader.ReadBEUInt16()
  if ([Enum]::IsDefined([Idented.Dns.AFSDBSubType], $SubType)) {
    $SubType = [KScript.DnsResolver.AFSDBSubType]$SubType
  }

  # Property: SubType
  $ResourceRecord | Add-Member SubType -MemberType NoteProperty -Value $SubType
  # Property: Hostname
  $ResourceRecord | Add-Member Hostname -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1}",
      $this.SubType,
      $this.Hostname)
  }
  
  return $ResourceRecord
}

