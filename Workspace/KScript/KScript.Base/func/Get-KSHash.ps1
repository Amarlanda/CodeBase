function Get-KSHash {
  # .SYNOPSIS
  #   Get a hash for the requested object.
  # .DESCRIPTION
  #   Generate a hash using .NET cryptographic service providers from the passed string, file or byte array.
  # .PARAMETER Algorithm
  #   The hashing algorithm to be used. By default, Get-KSHash generates an MD5 hash.
  #
  #   Available algorithms are MD5, SHA1, SHA256, SHA384 and SHA512.
  # .PARAMETER ByteArray
  #   Generate a hash from the byte array.
  # .PARAMETER FileName
  #   Generate a hash of the file.
  # .PARAMETER String
  #   Generate a hash from the specified string.
  # .INPUTS
  #   System.Byte[]
  #   System.String
  # .OUTPUTS
  #   System.Byte[]
  #   System.String
  # .EXAMPLE
  #   Get-ChildItem C:\Windows | Get-KSHash
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
  #     20/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding(DefaultParameterSetName = 'String')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true, ParameterSetName = 'String')]
    [String]$String,

    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true, ParameterSetName = 'FileName')]
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [Alias('FullName')]
    [String]$FileName,

    [Parameter(Mandatory = $true, ParameterSetName = 'ByteArray')]
    [Byte[]]$ByteArray,

    [ValidateSet('MD5', 'SHA1', 'SHA256', 'SHA384', 'SHA512')]
    [String]$Algorithm = "MD5",
    
    [Switch]$AsString
  )

  begin {
    $CryptoServiceProvider = switch ($Algorithm) {
      "MD5"    { New-Object Security.Cryptography.MD5CryptoServiceProvider; break }
      "SHA1"   { New-Object Security.Cryptography.SHA1CryptoServiceProvider; break }
      "SHA256" { New-Object Security.Cryptography.SHA256CryptoServiceProvider; break }
      "SHA384" { New-Object Security.Cryptography.SHA384CryptoServiceProvider; break }
      "SHA512" { New-Object Security.Cryptography.SHA512CryptoServiceProvider; break }
    }
  }

  process {
    if ($pscmdlet.ParameterSetName -eq 'String') {
      $ByteArray = ConvertTo-KSByte $String
    } elseif ($pscmdlet.ParameterSetName -eq 'FileName') {
      # Ensure the full path to the file is available
      $FullName = Get-Item $FileName | Select-Object -ExpandProperty FullName
      
      $FileStream = New-Object IO.FileStream($FullName, "Open", "Read", "Read")
      $ByteArray = New-Object Byte[] $FileStream.Length
      $FileStream.Read($ByteArray, 0, $FileStream.Length) | Out-Null
    }
    
    $HashValue = $CryptoServiceProvider.ComputeHash($ByteArray)
    
    if ($AsString) {
      ConvertTo-KSString $HashValue -Hexadecimal
    } else {
      $HashValue
    }
  }
  
  end {
    $CryptoServiceProvider.Dispose()
  }
}