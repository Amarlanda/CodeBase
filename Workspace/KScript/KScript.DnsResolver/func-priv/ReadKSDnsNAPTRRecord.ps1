function ReadKSDnsNAPTRRecord {
  # .SYNOPSIS
  #   Reads properties for an NAPTR record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     ORDER                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   PREFERENCE                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                     FLAGS                     /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   SERVICES                    /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    REGEXP                     /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  REPLACEMENT                  /
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
  #   KScript.DnsResolver.Message.ResourceRecord.NAPTR
  # .LINK
  #   http://www.ietf.org/rfc/rfc2915.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.NAPTR")
  
  # Property: Order
  $ResourceRecord | Add-Member Order -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: Preference
  $ResourceRecord | Add-Member Preference -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
  # Property: Flags
  $ResourceRecord | Add-Member Flags -MemberType NoteProperty -Value (ReadKSDnsCharacterString $BinaryReader)
  # Property: Service
  $ResourceRecord | Add-Member Service -MemberType NoteProperty -Value (ReadKSDnsCharacterString $BinaryReader)
  # Property: RegExp
  $ResourceRecord | Add-Member RegExp -MemberType NoteProperty -Value (ReadKSDnsCharacterString $BinaryReader)
  # Property: Replacement
  $ResourceRecord | Add-Member RegExp -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("`n" +
                     "    ;;  order    pref  flags  service       regexp              replacement`n" +
                     "        {0} {1} {2} {3} {4} {5}",
      $this.Order.ToString().PadRight(8, ' '),
      $this.Preference.ToString().PadRight(5, ' '),
      $this.Flags.PadRight(6, ' '),
      $this.Service.PadRight(13, ' '),
      $this.RegExp.PadRight(19, ' '),
      $this.Replacement)
  }
  
  return $ResourceRecord
}

