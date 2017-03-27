function NewKSDnsOPTRecord {
  # .SYNOPSIS
  #   Creates a new OPT record instance for advertising DNSSEC support.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Modified / simplified OPT record structure for advertising DNSSEC support. 
  #  
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+
  #    |         NAME          |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TYPE                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |              MAXIMUM PAYLOAD SIZE             |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |    EXTENDED-RCODE     |        VERSION        |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                       Z                       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   RDLENGTH                    |  
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .OUTPUTS
  #   KScript.DnsResolver.Message.ResourceRecord.OPT
  # .LINK
  #   http://www.ietf.org/rfc/rfc2671.txt

  [CmdLetBinding()]
  param( )
  
  $ResourceRecord = New-Object PsObject -Property ([Ordered]@{
    Name               = ".";
    RecordType         = [KScript.DnsResolver.RecordType]::OPT;
    MaximumPayloadSize = [UInt16]4096;
    ExtendedRCode      = 0;
    Version            = 0;
    Z                  = [KScript.DnsResolver.EDnsDNSSECOK]::DO;
    RecordDataLength   = 0;
  })
  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord")
  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.OPT")

  # Method: ToByte
  $ResourceRecord | Add-Member ToByte -MemberType ScriptMethod -Value {
    $Bytes = New-Object Byte[] 11
    
    # Property: RecordType
    $Bytes[2] = 0x29
    # Property: MaximumPayloadSize
    $MaximumPayloadSizeBytes = $this.MaximumPayloadSize | ConvertTo-KSByte -BigEndian
    [Array]::Copy($MaximumPayloadSizeBytes, 0, $Bytes, 3, 2)
    # Property: Z - DO bit
    $Bytes[7] = 0x80
    
    return [Byte[]]$Bytes
  }
  
  return $ResourceRecord
}

