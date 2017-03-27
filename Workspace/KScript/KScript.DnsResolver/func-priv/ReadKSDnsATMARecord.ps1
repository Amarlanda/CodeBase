function ReadKSDnsATMARecord {
  # .SYNOPSIS
  #   Reads properties for an ATMA record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |         FORMAT        |                       |
  #    +--+--+--+--+--+--+--+--+                       |
  #    /                   ATMADDRESS                  /
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
  #   KScript.DnsResolver.Message.ResourceRecord.ATMA
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.ATMA")
  
  # Format
  $Format = [KScript.DnsResolver.ATMAFormat]$BinaryReader.ReadByte()
  
  # ATMAAddress length, discounting the first byte (Format)
  $Length = $RecorceRecord.RecordDataLength - 1
  $ATMAAddress = New-Object Text.StringBuilder
  
  switch ($Format) {
    ([KScript.DnsResolver.ATMAFormat]::AESA) { 
      for ($i = 0; $i -lt $Length; $i++) {
        $ATMAAddress.Append($BinaryReader.ReadChar()) | Out-Null
      }
      break
    }
    ([KScript.DnsResolver.ATMAFormat]::E164) {
      for ($i = 0; $i -lt $Length; $i++) {
        if ((3, 6) -contains $i) { $ATMAAddress.Append(".") | Out-Null }
        $ATMAAddress.Append($BinaryReader.ReadChar()) | Out-Null
      }
      break
    }
    ([KScript.DnsResolver.ATMAFormat]::NSAP) {
      for ($i = 0; $i -lt $Length; $i++) {
        if ((1, 3, 13, 19) -contains $i) { $ATMAAddress.Append(".") | Out-Null }
        $ATMAAddress.Append(('{0:X2}' -f $BinaryReader.ReadByte())) | Out-Null
      }
      break
    }
  }

  # Property: Format
  $ResourceRecord | Add-Member Format -MemberType NoteProperty -Value $Format
  # Property: ATMAAddress
  $ResourceRecord | Add-Member ATMAAddress -MemberType NoteProperty -Value $ATMAAddress.ToString()

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    $this.ATMAAddress
  }
  
  return $ResourceRecord
}

