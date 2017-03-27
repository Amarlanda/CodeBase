function ReadKSDnsWINSRRecord {
  # .SYNOPSIS
  #   Reads properties for an WINSR record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  LOCAL FLAG                   |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                LOOKUP TIMEOUT                 |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                 CACHE TIMEOUT                 |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |               NUMBER OF SERVERS               |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  DOMAIN NAME                  /
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
  #   KScript.DnsResolver.Message.ResourceRecord.WINSR
  # .LINK
  #   http://msdn.microsoft.com/en-us/library/ms682748%28VS.85%29.aspx
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.WINSR")

  # Property: LocalFlag
  $ResourceRecord | Add-Member LocalFlag -MemberType NoteProperty -Value ([KScript.DnsResolver.WINSMappingFlag]$BinaryReader.ReadBEUInt32())
  # Property: LookupTimeout
  $ResourceRecord | Add-Member LookupTimeout -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
  # Property: CacheTimeout
  $ResourceRecord | Add-Member CacheTimeout -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
  # Property: NumberOfDomains
  $ResourceRecord | Add-Member NumberOfDomains -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
  # Property: DomainNameList
  $ResourceRecord | Add-Member DomainNameList -MemberType NoteProperty -Value @()
  
  for ($i = 0; $i -lt $ResourceRecord.NumberOfDomains; $i++) {
    $ResourceRecord.DomainNameList += ConvertToKSDnsDomainName $BinaryReader
  }

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    $Value = [String]::Format("L{0} C{1} ( {2} )",
      $this.LookupTimeout,
      $this.CacheTimeout,
      "$($this.DomainNameList)")
    if ($this.LocalFlag -eq [KScript.DnsResolver.WINSMappingFlag]::NoReplication) {
      $Value = "LOCAL $Value"
    }
    $Value
  }
  
  return $ResourceRecord
}

