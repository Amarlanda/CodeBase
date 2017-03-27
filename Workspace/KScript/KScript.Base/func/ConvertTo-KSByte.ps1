function ConvertTo-KSByte {
  # .SYNOPSIS
  #   Converts a value to a byte array.
  # .DESCRIPTION
  #   ConvertTo-KSByte acts as a wrapper for a number of .NET methods which return byte arrays.
  # .PARAMETER BigEndian
  #   If a multi-byte value is being returned this parameter can be used to reverse the byte order. By default, the least significant byte is returned first.
  #
  #   The BigEndian parameter is only effective when a numeric value is passed as the Value.
  # .PARAMETER Unicode
  #   Treat text strings as Unicode instead of ASCII.
  # .PARAMETER Value
  #   The value to convert. If a string value is passed it is treated as ASCII text and converted. If a numeric value is entered the type is tested an BitConverter.GetBytes is used.
  # .INPUTS
  #   System.Object
  # .OUTPUTS
  #   System.Byte[]
  # .EXAMPLE
  #   "The cow jumped over the moon" | ConvertTo-KSByte
  # .EXAMPLE
  #   123456 | ConvertTo-KSByte
  # .EXAMPLE
  #   [UInt16]60000 | ConvertTo-KSByte -BigEndian
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
  #     13/01/2015 - Chris Dent - Added Unicode option.
  #     24/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    $Value,

    [Switch]$BigEndian,

    [Switch]$Unicode
  )
  
  process {
    switch -Regex ($Value.GetType().Name) {
      'Byte|U?Int(16|32|64)' { 
        $Bytes = [BitConverter]::GetBytes($Value)
        if ($BigEndian) {
            [Array]::Reverse($Bytes)
        }
        return $Bytes
      }
      default {
        if ($Unicode) {
          return [Text.Encoding]::Unicode.GetBytes([String]$Value)
        } else {
          return [Text.Encoding]::ASCII.GetBytes([String]$Value)
        }
      }
    }
  }
}