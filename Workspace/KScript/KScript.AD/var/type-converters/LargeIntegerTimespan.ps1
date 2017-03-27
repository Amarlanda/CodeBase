# .SYNOPSIS
#   Convert from a Int64 or iADSLargeInteger to a timespan.
# .DESCRIPTION
#   Internal use only.
#
#   LargeIntegerDate is an attribute converter used to handle LargeIntegerTimespan values such as lockoutDuration.
# .PARAMETER Value
#   The value for the attribute returned by either System.DirectoryServices.DirectoryEntry or System.DirectoryServices.SearchResult.
# .INPUTS
#   System.UInt64
#   COMObject.iADSLargeInteger
# .OUTPUTS
#   System.Timespan
# .LINKS
#   http://msdn.microsoft.com/en-us/library/aa706037(v=vs.85).aspx
# .NOTES
#   Author: Chris Dent
#
#   Change log:
#     16/06/2014 - First release  
 

[CmdLetBinding()]
param(
  $AttributeValue
)

if ($AttributeValue -is [__ComObject]) {
  $Value = ConvertFromKSADLargeInteger $AttributeValue
} else {
  $Value = [Int64]$AttributeValue
}
# Convert to UInt64
# $Value = [UInt64][Math]::Abs($Value)

return New-Object TimeSpan($Value)