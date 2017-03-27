function Start-KSAutoUpdate {
  # .SYNOPSIS
  #   Start an update process for all installed KScript.* modules.
  # .DESCRIPTION
  #   Start-KSAutoUpdate attempts to update all installed KScript.* modules.
  # .EXAMPLE
  #   Start-KSAutoUpdate
  # .LINK
  #   http://www.indented.co.uk/indented-common/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies.
  #   Module: Indented.Common
  #
  #   (c) 2008-2014 Chris Dent.
  #
  #   Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, provided that the above copyright notice and this permission notice appear in all copies.
  #
  #   THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.  
  #
  #   Change log:
  #     04/07/2014 - Chris Dent - Modified to read settings using Get-KSSetting.
  #     20/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param( )
  
  if (Get-KSSetting KSModuleAutoUpdate -ExpandValue) {
    Get-KSModule |
      Where-Object { $_.LocalVersion -ne "Not installed" -and $_.ServerVersion -ne "Not available" } |
      ForEach-Object {
        if ($_.LocalVersion -lt $_.ServerVersion) {
          Write-Verbose "Start-KSAutoUpdate: Starting update for $($_.Name)"
          $_ | Install-KSModule
        } else {
          Write-Verbose "Start-KSAutoUpdate: $($_.Name) is up to date."
        }
      }
  } else {
    Write-Verbose "Start-KSAutoUpdate: Updates are not enabled" 
  }
}