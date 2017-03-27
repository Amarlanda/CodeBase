function Add-KSInternalDnsCacheRecord {
  # .SYNOPSIS
  #   Add a new CacheRecord to the DNS cache object.
  # .DESCRIPTION
  #   Cache records must expose the following property members:
  #
  #    - Name
  #    - TTL
  #    - RecordType
  #    - IPAddress
  #
  # .PARAMETER CacheRecord
  #   A record to add to the cache.
  # .PARAMETER Permanent
  #   A time property is used to age entries out of the cache. If permanent is set the time is not, the value will not be purged based on the TTL.
  # .INPUTS
  #   KScript.DnsResolver.Message.CacheRecord
  # .EXAMPLE
  #   $CacheRecord | Add-KSInternalDnsCacheRecord
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
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KSscript.DnsResolver.Message.CacheRecord' } )]
    $CacheRecord,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ResourceRecord')]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.DnsResolver.Message.ResourceRecord' } )]
    $ResourceRecord,
    
    [ValidateSet("Address", "Hint")]
    [String]$ResourceType = "Address",
    
    [Switch]$Permanent
  )

  begin {
    if (-not $Permanent) {
      $Time = Get-Date
    }
  }

  process {
    if ($ResourceRecord) {
      $TempObject = $ResourceRecord | Select-Object Name, TTL, RecordType, IPAddress
      $TempObject.PsObject.TypeNames.Add('KScript.DnsResolver.Message.CacheRecord')
      $CacheRecord = $TempObject
    }
  
    $CacheRecord | Add-Member ResourceType -MemberType NoteProperty -Value $ResourceType
    $CacheRecord | Add-Member Time -MemberType NoteProperty -Value $Time
    $CacheRecord | Add-Member Status -MemberType ScriptProperty -Value {
      if ($this.Time) {
        if ($this.Time.AddSeconds($this.TTL) -lt (Get-Date)) {
          "Expired"
        } else {
          "Active"
        }
      } else {
        "Permanent"
      }
    }
  
    if ($KSDnsCache.Contains($CacheRecord.Name)) {
      # Add the record to the cache if it doesn't already exist.
      if (-not ($CacheRecord | Get-KSInternalDnsCacheRecord)) {
        $KSDnsCache[$CacheRecord.Name] += $CacheRecord
      }
    } else {
      $KSDnsCache.Add($CacheRecord.Name, @($CacheRecord))
      if (-not ($KSDnsCacheReverse.Contains($CacheRecord.IPAddress))) {
        $KSDnsCacheReverse.Add($CacheRecord.IPAddress, $CacheRecord.Name)
      }
    }
  }      
}

