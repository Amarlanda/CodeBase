function ConvertTo-KSTimeSpanString {
  # .SYNOPSIS
  #   Converts a number of seconds to a string.
  # .DESCRIPTION
  #   ConvertTo-KSTimeSpanString accepts values in seconds then uses integer division to represent that time as a string.
  #
  #   ConvertTo-KSTimeSpanString accepts UInt32 values, overcoming the Int32 type limitation built into New-TimeSpan.
  #
  #   The format below is used, omitting any values of 0:
  #
  #   # weeks # days # hours # minutes # seconds
  #
  # .PARAMETER Seconds
  #   A number of seconds as an unsigned 32-bit integer. The maximum value is 4294967295 ([UInt32]::MaxValue).
  # .INPUTS
  #   System.UInt32
  # .OUTPUTS
  #   System.String  
  # .EXAMPLE
  #   ConvertTo-KSTimeSpanString 28800
  # .EXAMPLE
  #   [UInt32]::MaxValue | ConvertTo-KSTimeSpanString
  # .EXAMPLE
  #   86400, 700210 | ConvertTo-KSTimeSpanString
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
  #     13/01/2015 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeLine = $true)]
    [UInt32]$Seconds
  )

  begin {
    # Time periods described in seconds
    $Formats = [Ordered]@{
      week = 604800;
      day = 86400;
      hour = 3600;
      minute = 60;
      second = 1;
    }
  }
  
  process {
    $Values = $Formats.Keys | ForEach-Object {
      $Key = $_

      # Calculate the remainder prior to integer division
      $Remainder = $Seconds % $Formats[$Key]
      $Value = ($Seconds - $Remainder) / $Formats[$Key]
      # Decrement the original value
      $Seconds = $Remainder
      
      if ($Value) {
        # if the value is greater than 1, make the key name plural
        if ($Value -gt 1) { $Key = "$($Key)s" }
        
        "$Value $Key"
      }
    }
    return "$Values"
  }
}