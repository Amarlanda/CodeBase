function ReadKSDnsMessageQuestion {
  # .SYNOPSIS
  #   Reads a DNS question from a byte stream.
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
  #   A name value 
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-KSBinaryReader (Indented.Common) containing a byte array representing a DNS message.
  #
  #   If a binary reader is not passed as an argument an empty DNS question is returned.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-KSBinaryReader (Indented.Common)
  # .OUTPUTS
  #   KScript.DnsResolver.Message.Question

  [CmdLetBinding(DefaultParameterSetName = 'NewQuestion')]
  param(
    [Parameter(Position = 1, ParameterSetName = 'NewQuestion')]
    [String]$Name = ".",

    [Parameter(Position = 1, Mandatory = $true, ParameterSetName = 'ReadQuestion')]
    [IO.BinaryReader]$BinaryReader
  )

  $DnsMessageQuestion = NewKSDnsMessageQuestion

  # Property: Name
  $DnsMessageQuestion.Name = ConvertToKSDnsDomainName $BinaryReader
  # Property: RecordType
  $DnsMessageQuestion.RecordType = [KScript.DnsResolver.RecordType]$BinaryReader.ReadBEUInt16()
  # Property: RecordClass
  if ($DnsMessageQuestion.RecordType -eq [KScript.DnsResolver.RecordType]::OPT) {
    $DnsMessageQuestion.RecordClass = $BinaryReader.ReadBEUInt16()
  } else {
    $DnsMessageQuestion.RecordClass = [KScript.DnsResolver.RecordClass]$BinaryReader.ReadBEUInt16()
  }

  return $DnsMessageQuestion
}

