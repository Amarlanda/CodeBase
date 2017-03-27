function ConvertTo-KSString {
  # .SYNOPSIS
  #   Converts a byte array to a string value.
  # .DESCRIPTION
  #   ConvertTo-KSString supports a number of different binary encodings including ASCII, Base16 (Hexadecimal), Base64, Binary and Unicode.
  # .PARAMETER ASCII
  #   The byte array is an ASCII string.
  # .PARAMETER Base64
  #   The byte array is Base64 encoded string.
  # .PARAMETER Binary
  #   The byte array is a binary string.
  # .PARAMETER Hexadecimal
  #   The byte array is a hexadecimal string.
  # .PARAMETER Unicode
  #   The byte array is a Unicode string.
  # .INPUTS
  #   System.Byte[]
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   ConvertTo-KSString (72, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100)
  #
  #   Converts the byte array to an ASCII string.
  # .EXAMPLE
  #   ConvertTo-KSString (1, 2, 3, 4) -Base64
  #
  #   Converts the byte array to a Base64 string.
  # .EXAMPLE
  #   ConvertTo-KSString (1, 2, 3, 4) -Binary
  # 
  #   Converts the byte array to a binary string.
  # .EXAMPLE
  #   ConvertTo-KSString (1, 2, 3, 4) -Hexadecimal
  # 
  #   Converts the byte array to a hexadecimal string.
  # .EXAMPLE
  #   ConvertTo-KSString (72, 0, 101, 0, 108, 0, 108, 0, 111, 0, 32, 0, 119, 0, 111, 0, 114, 0, 108, 0, 100, 0) -Unicode
  #
  #   Converts the byte array to a unicode string.
  # .LINK
  #   http://www.indented.co.uk/indented-common/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #   Module: Indented.Common
  #
  #   (c) 2008-2014 Chris Dent.
  #
  #   Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, 
  #   provided that the above copyright notice and this permission notice appear in all copies.
  #
  #   THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED 
  #   WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR 
  #   CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF 
  #   CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  #
  #   Change log:
  #     24/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding(DefaultParameterSetName = 'ToASCII')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Byte[]]$Data,

    [Parameter(Mandatory = $true, ParameterSetName = 'ToBase64')]
    [Alias('ToBase64')]
    [Switch]$Base64,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ToBinary')]
    [Alias('ToBinary')]
    [Switch]$Binary,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ToHex')]
    [Alias('Hex', 'ToHex', 'Base16', 'ToBase16')]
    [Switch]$Hexadecimal,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ToUnicode')]
    [Alias('ToUnicode')]
    [Switch]$Unicode
  )

  process {
    switch ($pscmdlet.ParameterSetName) {
      'ToASCII' { 
        return [Text.Encoding]::ASCII.GetString($Data)
      }
      'ToBase64' {
        return [Convert]::ToBase64String($Data)
      }
      'ToBinary' {
        return (($Data | ForEach-Object { [Convert]::ToString($_, 2).PadLeft(8, '0') }) -join '')
      }
      'ToHex'   {
        $HexAlphabet = [Char[]]('0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'a', 'b', 'c', 'd', 'e', 'f')

        $Length = $Data.Length
        $ResultCharacters = New-Object Char[] ($Length * 2)
        for ($i = 0; $i -lt $Length; $i++) {
          [Byte]$Byte = $Data[$i]
          $j = $i * 2
          # Shift right to drop the last 4 bits. Allows conversion of the first of two characters.
          $ResultCharacters[$j] = $HexAlphabet[$Byte -shr 4]
          # Mask the last last 4 bits  with 00001111 (15 / 0x0F). Allows conversion of the second of two characters.
          $ResultCharacters[$j + 1] = $HexAlphabet[$Byte -band [Byte]0xF]
        }
        
        return New-Object String(,$ResultCharacters)
      }
      'ToUnicode' {
        return [Text.Encoding]::Unicode.GetString($Data)
      }
    }
  }
}
