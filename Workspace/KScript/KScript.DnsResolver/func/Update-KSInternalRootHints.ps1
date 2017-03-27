function Update-KSInternalRootHints {
  # .SYNOPSIS
  #   Updates the root hints file from InterNIC then re-initializes the internal cache.
  # .DESCRIPTION
  #   The root hints file is used as the basis of an internal DNS cache. The content of the root hints file is used during iterative name resolution.
  # .PARAMETER Source
  #   Update-KSInternalRootHints attempts to download a named.root file from InterNIC by default. An alternative root hints source may be specified here.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Update-KSInternalRootHints
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
    $Source = "http://www.internic.net/domain/named.root"
  )
  
  Get-WebContent $Source -File $psscriptroot\named.root
  Initialize-KSInternalDnsCache
}

