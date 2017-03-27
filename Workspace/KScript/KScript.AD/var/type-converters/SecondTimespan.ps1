# .SYNOPSIS
#   Convert a number of seconds as a 32-bit integer to a timespan.
# .DESCRIPTION
#   Internal use only.
#
#   SecondTimespan is an attribute converter used to handle Int32-based timespan values such as MaxPasswordAge (WinNT iADSUser interface).
# .PARAMETER Value
#   The value for the attribute returned by either System.DirectoryServices.DirectoryEntry or System.DirectoryServices.SearchResult.
# .INPUTS
#   System.Int32
# .OUTPUTS
#   System.Timespan
# .NOTES
#   Author: Chris Dent
#
#   Change log:
#     25/07/2014 - First release  
 

[CmdLetBinding()]
param(
  [Int32]$AttributeValue
)

if ($AttributeValue) {
  return (New-TimeSpan -Seconds $AttributeValue)
}