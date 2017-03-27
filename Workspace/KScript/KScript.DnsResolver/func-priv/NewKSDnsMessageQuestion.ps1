function NewKSDnsMessageQuestion {
  # .SYNOPSIS
  #   Creates a new DNS message question.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                     QNAME                     /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     QTYPE                     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                     QCLASS                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER Name
  #   A name value as a domain-name.
  # .PARAMETER RecordClass
  #   The record class, IN by default.
  # .PARAMETER RecordType
  #   The record type for the question. ANY by default.
  # .INPUTS
  #   System.String
  #   KScript.DnsResolver.RecordClass
  #   KScript.DnsResolver.RecordType
  # .OUTPUTS
  #   KScript.DnsResolver.Message.Question

  [CmdLetBinding()]
  param(
    [String]$Name,

    [KScript.DnsResolver.RecordClass]$RecordClass = [KScript.DnsResolver.RecordClass]::IN,

    [KScript.DnsResolver.RecordType]$RecordType = [KScript.DnsResolver.RecordType]::ANY
  )

  $DnsMessageQuestion = New-Object PsObject -Property ([Ordered]@{
    Name        = $Name;
    RecordClass = $RecordClass;
    RecordType  = $RecordType;
  })
  $DnsMessageQuestion.PsObject.TypeNames.Add("KScript.DnsResolver.Message.Question")

  # Method: ToByte
  $DnsMessageQuestion | Add-Member ToByte -MemberType ScriptMethod -Value {
    $Bytes = @()

    $Bytes += ConvertFromKSDnsDomainName $this.Name
    $Bytes += ConvertTo-KSByte ([UInt16]$this.RecordType) -BigEndian
    $Bytes += ConvertTo-KSByte ([UInt16]$this.RecordClass) -BigEndian

    return [Byte[]]$Bytes
  }

  # Method: ToString
  $DnsMessageQuestion | Add-Member ToString -MemberType ScriptMethod -Force -Value {
    return [String]::Format("{0}            {1} {2}",
      $this.Name.PadRight(29, ' '),
      $this.RecordClass.ToString().PadRight(5, ' '),
      $this.RecordType.ToString().PadRight(5, ' ')
    )
  }

  return $DnsMessageQuestion
}

