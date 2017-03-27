function ReadKSDnsA6Record {
  # .SYNOPSIS
  #   Reads properties for an CERT record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |      PREFIX LEN       |                       |
  #    +--+--+--+--+--+--+--+--+                       |
  #    /                ADDRESS SUFFIX                 /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  PREFIX NAME                  /
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
  #   The BinaryReader object must be created using New-KSBinaryReader (Indented.Common)
  # .OUTPUTS
  #   KScript.DnsResolver.Message.ResourceRecord.A6
  # .LINK
  #   http://www.ietf.org/rfc/rfc2874.txt
  #   http://www.ietf.org/rfc/rfc3226.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.A6")

  # Property: PrefixLength
  $PrefixLength = $Reader.ReadByte()
  $ResourceRecord | Add-Member PrefixLength -MemberType NoteProperty -Value $PrefixLength
  
  # Return the address suffix
  $Length = [Math]::Ceiling((128 - $PrefixLength) / 8)
  $AddressSuffixBytes = $BinaryReader.ReadBytes($Length)
  
  # Make the AddressSuffix 16 bytes long
  while ($AddressSuffixBytes.Length -lt 16) {
    $AddressSuffixBytes = @([Byte]0) + $AddressSuffixBytes
  }
  # Convert the address bytes to an IPv6 style string
  $IPv6AddressArray = @()
  for ($i = 0; $i -lt 16; $i += 2) {
    $IPv6AddressArray += [String]::Format('{0:X2}{1:X2}', $AddressSuffixBytes[$i], $AddressSuffixBytes[$i + 1])
  }
  $IPv6Address = [IPAddress]($IPv6AddressArray -join ':')
  
  # Property: AddressSuffix
  $ResourceRecord | Add-Member AddressSuffix -MemberType NoteProperty -Value $IPv6Address
  # Property: PrefixName
  $ResourceRecord | Add-Member PrefixName -MemberType NoteProperty -Value (ConvertToKSDnsDomainName $BinaryReader)
  
  # Property: RecordData
  $ResourceRecord | Add-Member RecordData -MemberType ScriptProperty -Force -Value {
    [String]::Format("{0} {1} {2}",
      $this.PrefixLength.ToString(),
      $this.AddressSuffix.IPAddressToString,
      $this.PrefixName)
  }
  
  return $ResourceRecord
}

