function ReadKSDnsWKSRecord {
  # .SYNOPSIS
  #   Reads properties for an WKS record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    ADDRESS                    |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       PROTOCOL        |                       /
  #    +--+--+--+--+--+--+--+--+                       /
  #    /                                               /
  #    /                   <BIT MAP>                   /
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
  #   KScript.DnsResolver.Message.ResourceRecord.WKS
  # .LINK
  #   http://www.ietf.org/rfc/rfc1035.txt
  #   http://www.ietf.org/rfc/rfc1010.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.WKS")

  # Property: IPAddress
  $ResourceRecord | Add-Member IPAddress -MemberType NoteProperty -Value $BinaryReader.ReadIPv4Address()
  # Property: IPProtocolNumber
  $ResourceRecord | Add-Member IPProtocolNumber -MemberType NoteProperty -Value $BinaryReader.ReadByte()
  # Property: IPProtocolType
  $ResourceRecord | Add-Member IPProtocolType -MemberType ScriptProperty -Value {
    [Net.Sockets.ProtocolType]$this.IPProtocolNumber
  }
  
  # BitMap length in bytes, discounting the first five bytes (IPAddress and ProtocolType).
  $Bytes = $BinaryReader.ReadBytes($ResourceRecord.RecordDataLength - 5)
  $BinaryString = ConvertTo-KSString $Bytes -Binary
  
  # Property: BitMap
  $ResourceRecord | Add-Member BitMap -MemberType NoteProperty -Value $BinaryString
  # Property: Ports (numeric)
  $ResourceRecord | Add-Member Ports -MemberType ScriptProperty -Value {
    $Length = $BinaryString.Length; $Ports = @()
    for ([UInt16]$i = 0; $i -lt $Length; $i++) {
      if ($BinaryString[$i] -eq 1) {
        $Ports += $i
      }
    }
    $Ports
  }

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} ( {2} )",
      $this.IPAddress,
      $this.IPProtocolType,
      "$($this.Ports)")
  }
  
  return $ResourceRecord
}

