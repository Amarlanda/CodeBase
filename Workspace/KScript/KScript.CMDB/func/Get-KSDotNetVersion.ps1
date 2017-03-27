function Get-KSDotNetVersion {
  # .SYNOPSIS
  #   Get all versions of .NET available on the local machine.
  # .DESCRIPTION
  #   Gets the installed versions of .NET from the registry on the local machine.
  # .OUTPUTS
  #   System.Management.Automation.PSCustomObject
  # .EXAMPLE
  #   Get-KSDotNetVersion
  # .LINK
  #   http://www.indented.co.uk/indented-common/
  #   http://msdn.microsoft.com/en-us/library/hh925568%28v=vs.110%29.aspx
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
  #     06/01/2015 - Chris Dent - BugFix: Parameter passing.
  #     05/01/2015 - Chris Dent - Updated to use Get-KSRegistryValue.
  #     23/07/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )
  
  Get-KSRegistryValue -Key "SOFTWARE\Microsoft\NET Framework Setup\NDP" -Hive HKLM -Recurse @psboundparameters |
    Where-Object { $_.Install -eq 1 -and $_.Version } |
    Select-Object `
      @{n='FrameworkVersion';e={ if ($_.Key -match '(v[^\\]+)') { $matches[1] } }},
      @{n='Version';e={ $_.Version }},
      @{n='ServicePack';e={ $_.SP }} |
    Group-Object Version | ForEach-Object {
      $_.Group[0]
    }
}