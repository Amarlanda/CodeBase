function ReadKSDnsAPLRecord {
  # .SYNOPSIS
  #   Reads properties for an APL record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                 ADDRESSFAMILY                 |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |        PREFIX         | N|     AFDLENGTH      |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                    AFDPART                    /
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
  #   KScript.DnsResolver.Message.ResourceRecord.APL
  # .LINK
  #   http://tools.ietf.org/html/rfc3123
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.APL")

  # Property: List
  $ResourceRecord | Add-Member List -MemberType NoteProperty -Value @()
  
  # RecordData handling - a counter to decrement
  $RecordDataLength = $ResourceRecord.RecordDataLength
  if ($RecordDataLength -gt 0) {
    do {
      $BinaryReader.SetMarker()

      $ListItem = New-Object PsObject -Property ([Ordered]@{
        AddressFamily = ([KScript.DnsResolver.IanaAddressFamily]$BinaryReader.ReadBEUInt16());
        Prefix        = $BinaryReader.ReadByte();
        Negation      = $false;
        AddressLength = 0;
        Address       = $null;
      })
      
      $NegationAndLength = $BinaryReader.ReadByte()
      # Property: Negation
      $ListItem.Negation = [Boolean]($NegationAndLength -band 0x0800)
      # Property: AddressLength
      $ListItem.AddressLength = $NegationAndLength -band 0x007F
      
      $AddressLength = [Math]::Ceiling($ResourceRecord.AddressLength / 8)
      $AddressBytes = $BinaryReader.ReadBytes($AddressLength)
            
      switch ($ListItem.AddressFamily) {
        ([KScript.DnsResolver.IanaAddressFamily]::IPv4) {
          while ($AddressBytes.Length -lt 4) {
            $AddressBytes = @([Byte]0) + $AddressBytes
          }
          $Address = [IPAddress]($AddressBytes -join '.')
                  
          break
        }
        ([KScript.DnsResolver.IanaAddressFamily]::IPv6) {
          while ($AddressBytes.Length -lt 16) {
            $AddressBytes = @([Byte]0) + $AddressBytes
          }
          $IPv6Address = @()
          for ($i = 0; $i -lt 16; $i += 2) {
            $IPv6Address += [String]::Format('{0:X2}{1:X2}', $AddressSuffixBytes[$i], $AddressSuffixBytes[$i + 1])
          }
          $Address = [IPAddress]($IPv6Address -join ':')

          break
        }
        default {
          $Address = $AddressBytes
        }
      }        

      # Property: Address
      $ListItem.Address = $Address
    
      $ResourceRecord.List += $ListItem
    
      $RecordDataLength = $RecordDataLength - $BinaryReader.BytesFromMarker
    } until ($RecordDataLength -eq 0)
  }
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    $Values = $this.List | ForEach-Object {
      [String]::Format("{0}{1}:{2}/{3}",
        $(if ($_.Negation) { "!" } else { "" }),
        ([UInt16]$_.AddressFamily),
        $_.Address,
        $_.Prefix)
    }
    if ($Values.Count -gt 1) {
      "( $Values )"
    } else {
      "$Values"
    }
  }
 
  return $ResourceRecord
}

