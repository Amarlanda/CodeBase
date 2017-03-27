function ReadKSDnsLOCRecord {
  # .SYNOPSIS
  #   Reads properties for an LOC record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |        VERSION        |         SIZE          |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |       HORIZ PRE       |       VERT PRE        |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   LATITUDE                    |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   LONGITUDE                   |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                   ALTITUDE                    |
  #    |                                               |
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
  #   KScript.DnsResolver.Message.ResourceRecord.LOC
  # .LINK
  #   http://www.ietf.org/rfc/rfc1876.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.LOC")
 
  # Property: Version
  $ResourceRecord | Add-Member Version -MemberType NoteProperty -Value $BinaryReader.ReadByte()

  # Size handling - Default value is 1m
  $Byte = $BinaryReader.ReadByte()
  $Base = $Byte -band 0xF0 -shr 4
  $Power = $Byte -band 0x0F
  $Value = ($Base * [Math]::Pow(10, $Power)) / 100
  # Property: Size
  $ResourceRecord | Add-Member Size -MemberType NoteProperty -Value $Value

  # HorizontalPrecision handling - Default value is 10000m
  $Byte = $BinaryReader.ReadByte()
  $Base = $Byte -band 0xF0 -shr 4
  $Power = $Byte -band 0x0F
  $Value = ($Base * [Math]::Pow(10, $Power)) / 100
  # Property: HorizontalPrecision
  $ResourceRecord | Add-Member HorizontalPrecision -MemberType NoteProperty -Value $Value
  
  # VerticalPrecision handling - Default value is 10m
  $Byte = $BinaryReader.ReadByte()
  $Base = $Byte -band 0xF0 -shr 4
  $Power = $Byte -band 0x0F
  $Value = ($Base * [Math]::Pow(10, $Power)) / 100
  # Property: VerticalPrecision
  $ResourceRecord | Add-Member VerticalPrecision -MemberType NoteProperty -Value $Value
 
  # Property: LatitudeRawValue
  $ResourceRecord | Add-Member LatitudeRawValue -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
  # Property: Latitude
  $ResourceRecord | Add-Member Latitude -MemberType ScriptProperty -Value {
    $Equator = [Math]::Pow(2, 31)
    if ($this.LatitudeRawValue -gt $Equator) {
      $Direction = "S"
    } else {
      $Direction = "N"
    }
    # Degrees
    $Remainder = $Value % (1000 * 60 * 60)
    $Degrees = ($Value - $Remainder) / (1000 * 60 * 60)
    $Value = $Remainder
    # Minutes
    $Remainder = $Value % (1000 * 60)
    $Minutes = ($Value - $Remainder) / (1000 * 60)
    $Value = $Remainder
    # Seconds
    $Seconds = $Value / 1000
    # Return value
    "$Degrees $Minutes $Seconds $Direction"
  }
  # Property: LatitudeToString
  $ResourceRecord | Add-Member LatitudeToString -MemberType ScriptProperty -Value {
    $Values = $this.Latitude -split ' '
    [String]::Format("{0} degrees {1} minutes {2} seconds {3}",
      $Values[0],
      $Values[1],
      $Values[2],
      $Values[3])
  }
  
  # Property: LongitudeRawValue
  $ResourceRecord | Add-Member LongitudeRawValue -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()
  # Property: Longitude
  $ResourceRecord | Add-Member Longitude -MemberType ScriptProperty -Value {
    $PrimeMeridian = [Math]::Pow(2, 31)
    if ($this.LongitudeRawValue -gt $PrimeMeridian) {
      $Direction = "E"
    } else {
      $Direction = "W"
    }
    # Degrees
    $Remainder = $Value % (1000 * 60 * 60)
    $Degrees = ($Value - $Remainder) / (1000 * 60 * 60)
    $Value = $Remainder
    # Minutes
    $Remainder = $Value % (1000 * 60)
    $Minutes = ($Value - $Remainder) / (1000 * 60)
    $Value = $Remainder
    # Seconds
    $Seconds = $Value / 1000
    # Return value
    "$Degrees $Minutes $Seconds $Direction"
  }
  # Property: LongitudeToString
  $ResourceRecord | Add-Member LongitudeToString -MemberType ScriptProperty -Value {
    $Values = $this.Longitude -split ' '
    [String]::Format("{0} degrees {1} minutes {2} seconds {3}",
      $Values[0],
      $Values[1],
      $Values[2],
      $Values[3])
  }

  # Property: Altitude
  $ResourceRecord | Add-Member Altitude -MemberType NoteProperty -Value ($BinaryReader.ReadBEUInt32() / 100)

  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2} {3}m {4}m {5}m",
      $this.Latitude,
      $this.Longitude,
      $this.Altitude,
      $this.Size,
      $this.HorizontalPrecision,
      $this.VerticalPrecision
    )
  }
  
  return $ResourceRecord
}

