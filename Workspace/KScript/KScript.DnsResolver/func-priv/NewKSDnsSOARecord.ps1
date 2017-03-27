function NewKSDnsSOARecord {
  # .SYNOPSIS
  #   Creates a new SOA record instance for use with IXFR queries.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Modified / simplified SOA record structure for executing IXFR transfers. 
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      NAME                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TYPE                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     CLASS                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                      TTL                      |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   RDLENGTH                    |  
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     MNAME                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     RNAME                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    SERIAL                     |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    REFRESH                    |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     RETRY                     |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    EXPIRE                     |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    MINIMUM                    |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER Name
  #   Name is passed into this CmdLet as an optional aesthetic value. It serves no real purpose. 
  #
  #   All Name values (Name, NameServer and ResponsiblePerson) are referenced using a message compression flag with the offset set to 12, the name used in the Question.
  # .PARAMETER Serial
  #   A serial number to pass with the IXFR request.
  # .INPUTS
  #   System.String
  #   System.UInt32
  # .OUTPUTS
  #   System.Byte[]

  param(
    [String]$Name = ".",

    [Parameter(Mandatory = $true)]
    [UInt32]$SerialNumber
  )

  $ResourceRecord = New-Object PsObject -Property ([Ordered]@{
    Name              = $Name;
    TTL               = 0;
    RecordClass       = [KScript.DnsResolver.RecordClass]::IN;
    RecordType        = [KScript.DnsResolver.RecordType]::SOA;
    RecordDataLength  = 24;
    NameServer        = $Name;
    ResponsiblePerson = $Name;
    Serial            = $SerialNumber;
    Refresh           = 0;
    Retry             = 0;
    Expire            = 0;
    MinimumTTL        = 0;
  })
  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord")
  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.SOA")

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} (`n" +
                     "    {2} ; serial`n" +
                     "    {3} ; refresh`n" +
                     "    {4} ; retry`n" +
                     "    {5} ; expire`n" +
                     "    {6} ; minimum ttl`n" +
                     ")",
      $this.NameServer,
      $this.ResponsiblePerson,
      $this.Serial.ToString().PadRight(10, ' '),
      $this.Refresh.ToString().PadRight(10, ' '),
      $this.Retry.ToString().PadRight(10, ' '),
      $this.Expire.ToString().PadRight(10, ' '),
      $this.MinimumTTL.ToString().PadRight(10, ' ')
    )
  }

  # Method: ToByte
  $ResourceRecord | Add-Member ToByte -MemberType ScriptMethod -Value {
    $Bytes = New-Object Byte[] 36
    
    # Property: Name
    $Bytes[0] = 0xC0; $Bytes[1] = 0x0C
    # Property: RecordType
    $Bytes[3] = 0x06;
    # Property: RecordClass
    $Bytes[5] = 0x01;
    # Property: RecordDataLength
    $Bytes[11] = 0x18;
    # Property: NameServer
    $Bytes[12] = 0xC0; $Bytes[13] = 0x0C
    # Property: ResponsiblePerson
    $Bytes[14] = 0xC0; $Bytes[15] = 0x0C
    # Property: SerialNumber
    $SerialBytes = $this.Serial | ConvertTo-KSByte -BigEndian
    [Array]::Copy($SerialBytes, 0, $Bytes, 16, 4)

    return [Byte[]]$Bytes
  }

  return $ResourceRecord
}

