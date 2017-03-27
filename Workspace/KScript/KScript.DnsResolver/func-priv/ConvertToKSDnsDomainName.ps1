function ConvertToKSDnsDomainName {
  # .SYNOPSIS
  #   Converts a DNS domain name from a byte stream to a string. This CmdLet also expands compressed names.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   DNS messages implement compression to avoid bloat by repeated use of labels.
  #
  #   If a label occurs elsewhere in the message a flag is set and an offset recorded as follows:
  #
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    | 1  1|                OFFSET                   |
  #    +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-KSBinaryReader (KScript.NetworkTools) containing a byte array representing a DNS resource record.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-KSBinaryReader (KScript.NetworkTools)
  # .OUTPUTS
  #   System.String
  # .LINK
  #   http://www.ietf.org/rfc/rfc1035.txt

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader
  )

  $Name = New-Object Text.StringBuilder
  [UInt64]$CompressionStart = 0
  
  # Read until we find the null terminator
  while ($BinaryReader.PeekByte() -ne 0) {
    # The length or compression reference
    $Length = $BinaryReader.ReadByte()
    
    if (($Length -band [KScript.DnsResolver.MessageCompression]::Enabled) -eq [KScript.DnsResolver.MessageCompression]::Enabled) {
      # Record the current position as the start of the compression operation.
      # Reader will be returned here after this operation is complete.
      if ($CompressionStart -eq 0) {
        $CompressionStart = $BinaryReader.BaseStream.Position
      }
      # Remove the compression flag bits to calculate the offset value (relative to the start of the message)
      [UInt16]$Offset = ([UInt16]($Length -bxor [KScript.DnsResolver.MessageCompression]::Enabled) -shl 8) -bor $BinaryReader.ReadByte()
      # Move to the offset
      $BinaryReader.BaseStream.Seek($Offset, 0) | Out-Null
    } else {
      # Read a label
      $Name.Append($BinaryReader.ReadChars($Length)) | Out-Null
      $null = $Name.Append('.')
    }
  }
  # If expansion was used, return to the starting point (plus 1 byte)
  if ($CompressionStart -gt 0) {
    $BinaryReader.BaseStream.Seek($CompressionStart, 0) | Out-Null
  }
  # Read off and discard the null termination on the end of the name
  $BinaryReader.ReadByte() | Out-Null
  
  $NameString = $Name.ToString()
  if (-not $NameString.EndsWith('.')) {
    $NameString = "$NameString."
  }
    
  return $NameString
}

