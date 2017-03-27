function ReadKSDnsOPTRecord {
  # .SYNOPSIS
  #   Reads properties for an OPT record from a byte stream.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   OPT records make the following changes to standard resource record fields:
  #
  #   Field Name   Field Type     Description
  #   ----------   ----------     -----------
  #   NAME         domain name    empty (root domain)
  #   TYPE         u_int16_t      OPT
  #   CLASS        u_int16_t      sender's UDP payload size
  #   TTL          u_int32_t      extended RCODE and flags
  #   RDLEN        u_int16_t      describes RDATA
  #   RDATA        octet stream   {attribute,value} pairs
  # 
  #   The Extended RCODE (stored in the TTL) is formatted as follows:
  #  
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |    EXTENDED-RCODE     |        VERSION        |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                       Z                       |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  #   RR data structure:
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  OPTION-CODE                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                 OPTION-LENGTH                 |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    /                  OPTION-DATA                  /
  #    /                                               /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  #   Processing for each option assigned by IANA has been added as described below.
  #
  #   LLQ
  #   ---
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  OPTION-CODE                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                 OPTION-LENGTH                 |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                    VERSION                    |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  LLQ-OPCODE                   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  ERROR-CODE                   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
  #    |                    LLQ-ID                     |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
  #    |                  LEASE-LIFE                   |
  #    |                                               |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  # 
  #   NSID
  #   ----
  #
  #   Option data is returned as a byte array (NSIDBytes) and an ASCII string (NSIDString).
  #
  #   DUA, DHU and N3U
  #   ----------------
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  OPTION-CODE                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  LIST-LENGTH                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |        ALG-CODE       |          ...          /
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  #   EDNS-client-subnet
  #   ------------------
  #
  #                                    1  1  1  1  1  1
  #      0  1  2  3  4  5  6  7  8  9  0  1  2  3  4  5
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                  OPTION-CODE                  |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                 OPTION-LENGTH                 |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |                 ADDRESSFAMILY                 |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    |    SOURCE NETMASK     |     SCOPE NETMASK     |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+  
  #    /                    ADDRESS                    /
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
  #   KScript.DnsResolver.Message.ResourceRecord.OPT
  # .LINK
  #   http://www.ietf.org/rfc/rfc2671.txt
  #   http://files.dns-sd.org/draft-sekar-dns-llq.txt
  #   http://files.dns-sd.org/draft-sekar-dns-ul.txt
  #   http://www.ietf.org/rfc/rfc5001.txt
  #   http://www.ietf.org/rfc/rfc6975.txt
  #   http://www.ietf.org/id/draft-vandergaast-edns-client-subnet-02.txt
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader,
    
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord
  )

  $ResourceRecord.PsObject.TypeNames.Add("KScript.DnsResolver.Message.ResourceRecord.OPT")

  # Property: MaximumPayloadSize - A copy of the data held in Class
  $ResourceRecord | Add-Member MaximumPayloadSize -MemberType NoteProperty -Value $ResourceRecord.RecordClass
  # Property: ExtendedRCode
  $ResourceRecord | Add-Member ExtendedRCode -MemberType NoteProperty -Value ([KScript.DnsResolver.RCode][UInt16]($ResourceRecord.TTL -shr 24))
  # Property: Version
  $ResourceRecord | Add-Member Version -MemberType NoteProperty -Value ($ResourceRecord.TTL -band 0x00FF0000)
  # Property: DNSSECOK
  $ResourceRecord | Add-Member DNSSECOK -MemberType NoteProperty -Value ([KScript.DnsResolver.EDnsDNSSECOK]($ResourceRecord.TTL -band 0x00008000))
  # Property: Options - A container for individual options
  $ResourceRecord | Add-Member Options -MemberType NoteProperty -Value @()
  
  # RecordData handling - a counter to decrement
  $RecordDataLength = $ResourceRecord.RecordDataLength
  if ($RecordDataLength -gt 0) {
    do {
      $BinaryReader.SetMarker()
    
      $Option = New-Object PsObject -Property ([Ordered]@{
        OptionCode   = ([KScript.DnsResolver.EDnsOptionCode]$BinaryReader.ReadBEUInt16());
        OptionLength = ($BinaryReader.ReadBEUInt16());
      })
   
      switch ($Option.OptionCode) {
        ([KScript.DnsResolver.EDnsOptionCode]::LLQ) {
          # Property: Version
          $Option | Add-Member Version -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt16()
          # Property: OpCode
          $Option | Add-Member OpCode -MemberType NoteProperty -Value ([KScript.DnsResolver.LLQOpCode]$BinaryReader.ReadBEUInt16())
          # Property: ErrorCode
          $Option | Add-Member ErrorCode -MemberType NoteProperty -Value ([KScript.DnsResolver.LLQErrorCode]$BinaryReader.ReadBEUInt16())
          # Property: ID
          $Option | Add-Member ID -MemberType NoteProprery -Value $BinaryReader.ReadBEUInt64()
          # Property: LeaseLife
          $Option | Add-Member LeaseLife -MemberType NoteProperty -Value $BinaryReader.ReadBEUInt32()

          break        
        }
        ([KScript.DnsResolver.EDnsOptionCode]::UL) {
          # Property: Lease
          $Option | Add-Member Lease -MemberType NoteProperty -Value $BinaryReader.ReadBEInt32()
        
          break
        }
        ([KScript.DnsResolver.EDnsOptionCode]::NSID) {
          $Bytes = $BinaryReader.ReadBytes($Option.OptionLength)
        
          # Property: Bytes
          $Option | Add-Member Bytes -MemberType NoteProperty -Value $Bytes
          # Property: String
          $Option | Add-Member String -MemberType NoteProperty -Value (ConvertTo-KSString $Bytes)
          
          break
        }
        ([KScript.DnsResolver.EDnsOptionCode]::DAU) {
          # Property: Algorithm
          $Option | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
          # Property: HashBytes
          $Bytes = $BinaryReader.ReadBytes($Option.OptionLength)
          $Base64String = ConvertTo-KSString $Bytes -Base64
          $Option | Add-Member HashBytes -MemberType NoteProperty -Value $Base64String
        
          break
        }
        ([KScript.DnsResolver.EDnsOptionCode]::DHU) {
          # Property: Algorithm
          $Option | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
          # Property: HashBytes
          $Bytes = $BinaryReader.ReadBytes($Option.OptionLength)
          $Base64String = ConvertTo-KSString $Bytes -Base64
          $Option | Add-Member HashBytes -MemberType NoteProperty -Value $Base64String
        
          break
        }
        ([KScript.DnsResolver.EDnsOptionCode]::N3U) {
          # Property: Algorithm
          $Option | Add-Member Algorithm -MemberType NoteProperty -Value ([KScript.DnsResolver.EncryptionAlgorithm]$BinaryReader.ReadByte())
          # Property: HashBytes
          $Bytes = $BinaryReader.ReadBytes($Option.OptionLength)
          $Base64String = ConvertTo-KSString $Bytes -Base64
          $Option | Add-Member HashBytes -MemberType NoteProperty -Value $Base64String
        
          break
        }
        ([KScript.DnsResolver.EDnsOptionCode]::"EDNS-client-subnet") {
          # Property: AddressFamily
          $Option | Add-Member AddressFamily -MemberType NoteProperty -Value ([KScript.DnsResolver.IanaAddressFamily]$BinaryReader.ReadBEUInt16())
          # Property: SourceNetMask
          $Option | Add-Member SourceNetMask -MemberType NoteProperty -Value $BinaryReader.ReadByte()
          # Property: ScopeNetMask
          $Option | Add-Member ScopeNetMask -MemberType NoteProperty -Value $BinaryReader.ReadByte()

          $AddressLength = [Math]::Ceiling($Option.SourceNetMask / 8)
          $AddressBytes = $BinaryReader.ReadBytes($AddressLength)
          
          switch ($Option.AddressFamily) {
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
          $Option | Add-Member Address -MemberType NoteProperty -Value $Address

          break
        }
        default {
          $Option | Add-Member OptionData -MemberType NoteProperty -Value $BinaryReader.ReadBytes($Option.OptionLength)
        }
      }
      
      $ResourceRecord.Options += $Option
      
      $RecordDataLength = $RecordDataLength - $BinaryReader.BytesFromMarker
    } until ($RecordDataLength -eq 0)
  }
  
  return $ResourceRecord
}

