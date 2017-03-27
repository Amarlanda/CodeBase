# .SYNOPSIS
#   Convert from a Int64 or iADSLargeInteger to a date.
# .DESCRIPTION
#   Internal use only.
#
#   LargeIntegerDate is an attribute converter used to handle LargeIntegerDate values such as accountExpires.
# .PARAMETER Value
#   The value for the attribute returned by either System.DirectoryServices.DirectoryEntry or System.DirectoryServices.SearchResult.
# .INPUTS
#   System.UInt64
#   COMObject.iADSLargeInteger
# .OUTPUTS
#   System.DateTime
# .LINKS
#   http://msdn.microsoft.com/en-us/library/aa706037(v=vs.85).aspx
#   http://msdn.microsoft.com/en-gb/library/ms675098.aspx
# .NOTES
#   Author: Chris Dent
#
#   Change log:
#     13/06/2014 - First release  
 

[CmdLetBinding()]
param(
  $AttributeValue
)

if ($AttributeValue -is [__ComObject]) {
  $Value = ConvertFromKSADLargeInteger $AttributeValue
} else {
  $Value = [UInt64]$AttributeValue
}

if ($Value -eq 0 -or $Value -eq 0x7FFFFFFFFFFFFFFF) {
  return $null
} else {
  return [DateTime]::FromFileTimeUtc($Value).ToLocalTime()
}