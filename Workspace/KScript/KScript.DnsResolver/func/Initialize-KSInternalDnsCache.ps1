function Initialize-KSInternalDnsCache {
  # .SYNOPSIS
  #   Initializes a basic DNS cache for use by Get-KSDns.
  # .DESCRIPTION
  #   Get-KSDns maintains a limited DNS cache, capturing A and AAAA records, to assist name server resolution (for values passed using the Server parameter).
  #
  #   The cache may be manipulated using *-InternalDnsCacheRecord CmdLets.
  # .EXAMPLE
  #   Initialize-KSInternalDnsCache
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
  param( )
  
  # These two variables are consumed by all other -InternalDnsCacheRecord CmdLets.
  
  # The primary cache variable stores a stub resource record
  if (Get-Variable KSDnsCache -Scope Script -ErrorAction SilentlyContinue) {
    Remove-Variable KSDnsCache -Scope Script
  }
  New-Variable KSDnsCache -Scope Script -Value @{}

  # Allows quick, if limited, reverse lookups against the cache.
  if (Get-Variable KSDnsCacheReverse -Scope Script -ErrorAction SilentlyContinue) {
    Remove-Variable KSDnsCache -Scope Script
  }
  New-Variable KSDnsCacheReverse -Scope Script -Value @{}
  
  if (Test-Path $psscriptroot\var\named.root) {
    Get-Content $psscriptroot\var\named.root | 
      Where-Object { $_ -match '(?<Name>\S+)\s+(?<TTL>\d+)\s+(IN\s+)?(?<RecordType>A\s+|AAAA\s+)(?<IPAddress>\S+)' } |
      ForEach-Object {
        $CacheRecord = New-Object PsObject -Property ([Ordered]@{
          Name       = $matches.Name;
          TTL        = [UInt32]$matches.TTL;
          RecordType = [KScript.DnsResolver.RecordType]$matches.RecordType;
          IPAddress  = [IPAddress]$matches.IPAddress;
        })
        $CacheRecord.PsObject.TypeNames.Add('KScript.DnsResolver.Message.CacheRecord')
        $CacheRecord
      } |
      Add-KSInternalDnsCacheRecord -Permanent -ResourceType Hint
  }
}

