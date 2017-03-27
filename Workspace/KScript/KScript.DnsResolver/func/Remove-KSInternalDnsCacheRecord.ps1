function Remove-KSInternalDnsCacheRecord {
  # .SYNOPSIS
  #   Remove an entry from the DNS cache object.
  # .DESCRIPTION
  #   Remove-KSInternalDnsCacheRecord allows the removal of individual records from the cache, or removal of all records which expired.
  # .PARAMETER CacheRecord
  #   A record to add to the cache.
  # .PARAMETER Permanent
  #   A time property is used to age entries out of the cache. If permanent is set the time is not, the value will not be purged based on the TTL.
  # .INPUTS
  #   KScript.DnsResolver.RecordType
  #   System.Net.IPAddress
  #   System.String
  # .EXAMPLE
  #   Get-KSInternalDnsCacheRecord a.root-servers.net | Remove-KSInternalDnsCacheRecord
  # .EXAMPLE
  #   Remove-KSInternalDnsCacheRecord -AllExpired
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
  
  [CmdLetBinding(DefaultParameterSetName = 'CacheRecord')]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'CacheRecord')]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.CacheRecord' } )]
    $CacheRecord,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'AllExpired')]
    [Switch]$AllExpired
  )
  
  begin {
    if ($AllExpired) {
      $ExpiredRecords = Get-KSInternalDnsCacheRecord | Where-Object { $_.Status -eq 'Expired' }
      $ExpiredRecords | Remove-KSInternalDnsCacheRecord
    }
  }
  
  process {
    if (-not $AllExpired) {
      if ($KSDnsCacheReverse.Contains($CacheRecord.IPAddress)) {
        $KSDnsCacheReverse.Remove($CacheRecord.IPAddress)
      }
      if ($KSDnsCache.Contains($CacheRecord.Name)) {
        $KSDnsCache[$CacheRecord.Name] = $KSDnsCache[$CacheRecord.Name] | Where-Object { $_.IPAddress -ne $CacheRecord.IPAddress -and $_.RecordType -ne $CacheRecord.RecordType }
        if ($KSDnsCache[$CacheRecord.Name].Count -eq 0) {
          $KSDnsCache.Remove($CacheRecord.Name)
        }
      }
    }
  }
}

