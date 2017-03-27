function Get-KSInternalDnsCacheRecord {
  # .SYNOPSIS
  #   Get the content of the internal DNS cache used by Get-KSDns.
  # .DESCRIPTION
  #   Get-KSInternalDnsCacheRecord displays records held in the cache.
  # .INPUTS
  #   KScript.DnsResolver.RecordType
  #   System.Net.IPAddress
  #   System.String
  # .OUTPUTS
  #   KScript.DnsResolver.Message.CacheRecord
  # .EXAMPLE
  #   Get-KSInternalDnsCacheRecord
  # .EXAMPLE
  #   Get-KSInternalDnsCacheRecord a.root-servers.net A
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #   Module: KScript.DnsResolver
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
    [Parameter(Position = 1, ValueFromPipelineByPropertyName = $true)]
    [String]$Name,
    
    [Parameter(Position = 2, ValueFromPipelineByPropertyName = $true)]
    [KScript.DnsResolver.RecordType]$RecordType,
    
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [IPAddress]$IPAddress,

    [ValidateSet("Address", "Hint")]
    [String]$ResourceType
  )
  
  process {
    $WhereStatementText = '$_'
    if ($ResourceType) {
      $WhereStatementText = $WhereStatementText + ' -and $_.ResourceType -eq $ResourceType'
    }
    if ($RecordType) {
      $WhereStatementText = $WhereStatementText + ' -and $_.RecordType -eq $RecordType'
    }
    if ($IPAddress) {
      $WhereStatementText = $WhereStatementText + ' -and $_.IPAddress -eq $IPAddress'
    }
    # Create a ScriptBlock using the statements above.
    $WhereStatement = [ScriptBlock]::Create($WhereStatementText)
    
    if ($Name) {
      if (-not $Name.EndsWith('.')) {
        $Name = "$Name."
      }
      if ($KSDnsCache.Contains($Name)) {
        $KSDnsCache[$Name] | Where-Object $WhereStatement
      }
    } else {
      # Each key may contain multiple values. Forcing a pass through ForEach-Object will
      # remove the multi-dimensional aspect of the return value.
      $KSDnsCache.Values | ForEach-Object { $_ } | Where-Object $WhereStatement
    }
  }
}

