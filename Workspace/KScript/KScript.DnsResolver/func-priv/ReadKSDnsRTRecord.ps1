function ReadKSDnsRTRecord {
  # .SYNOPSIS
  #   Reads properties for an RT record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  PREFERENCE                   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   EXCHANGE                    /
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
  #   KScript.DnsResolver.Message.ResourceRecord.RT
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

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.RT")
  
  # Property: Preference
  $ResourceRecord | Add-Member Preference -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: IntermediateHost
  $ResourceRecord | Add-Member IntermediateHost -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1}",
      $this.Preference.ToString().PadRight(5, ' '),
      $this.IntermediateHost)
  }
  
  return $ResourceRecord
}

