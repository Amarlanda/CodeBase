function ReadKSDnsCharacterString {
  # .SYNOPSIS
  #   Reads a character-string from a DNS message.
  # .DESCRIPTION
  #   Internal use only.
  # .PARAMETER BinaryReader
  #   A binary reader created by using New-KSBinaryReader (Indented.Common) containing a byte array representing a DNS resource record.
  # .INPUTS
  #   System.IO.BinaryReader
  #
  #   The BinaryReader object must be created using New-KSBinaryReader (Indented.Common)
  # .OUTPUTS
  #   System.String
  # .LINK
  #   http://www.ietf.org/rfc/rfc1035.txt

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [IO.BinaryReader]$BinaryReader
  )
  
  $Length = $BinaryReader.ReadByte()
  $CharacterString = New-Object String (,$BinaryReader.ReadChars($Length))
  
  return $CharacterString
}

