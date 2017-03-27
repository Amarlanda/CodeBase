#
# Module loader for KScript.Utility
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   05/01/2015 - Chris Dent - Moved Get-KSDotNetVersion to KScript.CMDB and removed dependency.
#   11/08/2014 - Chris Dent - Added Select-KSString.
#   05/08/2014 - Chris Dent - Added ConvertTo-KSXml.
#   23/07/2014 - Chris Dent - Removed System.IO.Compression assembly requirement from manifest; Implemented soft-check here.
#   18/07/2014 - Chris Dent - Added change logging here.

# Public functions
[Array]$Public = 'Export-KSExcelWorksheet',
                 'Import-KSExcelWorksheet',
                 'Resize-KSImageFile',
                 'Select-KSString'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}

# .NET version dependent public functions
$DotNetVersions = Get-ChildItem "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP" -Recurse |
    Where-Object { $_.GetValue("Install", "") -eq 1 -and $_.GetValue("Version", "") -ne "" } |
    ForEach-Object {
      $_.Name -match '(v[^\\]+)' | Out-Null
      New-Object PsObject -Property ([Ordered]@{
          FrameworkVersion = $matches[1];
          Version          = $_.GetValue("Version");
          ServicePack      = $_.GetValue("SP");
      })
    } |
    Group-Object Version | ForEach-Object {
      $_.Group[0]
    }
if ($DotNetVersions | Where-Object FrameworkVersion -eq 'v4.0') {
  Add-Type -Assembly 'System.IO.Compression'
  Add-Type -Assembly 'System.IO.Compression.FileSystem, Version=4.0.0.0, Culture=neutral, PublicKeyToken=b77a5c561934e089'

  # Public functions
  $Public = 'Compress-KSItem',
            'Expand-KSItem'
  
  if ($Public.Count -ge 1) {
    $Public | ForEach-Object {
      Import-Module "$psscriptroot\func\$_.ps1"
    }
  }
}