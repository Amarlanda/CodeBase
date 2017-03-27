function ReadKSDnsNSECRecord {
  # .SYNOPSIS
  #   Reads properties for an NSEC record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   DOMAINNAME                  /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                   <BIT MAP>                   /
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
  #   KScript.DnsResolver.Message.ResourceRecord.NSEC
  # .LINK
  #   http://www.ietf.org/rfc/rfc3755.txt
  #   http://www.ietf.org/rfc/rfc4034.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.NSEC")
  
  # Property: DomainName
  $ResourceRecord | Add-Member DomainName -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)
  # Property: RRTypeBitMap
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - $BinaryReader.BytesFromMarker)
  $BinaryString = ConvertTo-KSString $Bytes -Binary
  $ResourceRecord | Add-Member RRTypeBitMap -MemberType NoteProperty -Value $BinaryString
  # Property: RRTypes
  $ResourceRecord | Add-Member RRTypes -MemberType ScriptProperty -Value {
    $RRTypes = @()
    [Enum]::GetNames([KScript.DnsResolver.RecordType]) |
      Where-Object { [UInt16][KScript.DnsResolver.RecordType]::$_ -lt $BinaryString.Length -and 
        $BinaryString[([UInt16][KScript.DnsResolver.RecordType]::$_)] -eq '1' } |
      ForEach-Object {
        $RRTypes += [KScript.DnsResolver.RecordType]::$_
      }
    $RRTypes
  }

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2}",
      $this.DomainName,
      "$($this.RRTypes)")
  }
  
  return $ResourceRecord
}

