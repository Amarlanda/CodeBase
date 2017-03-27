# .SYNOPSIS
#   Convert a byte array to System.GUID.
# .DESCRIPTION
#   Internal use only.
# .PARAMETER Value
#   The value for the attribute returned by either System.DirectoryServices.DirectoryEntry or System.DirectoryServices.SearchResult.
# .INPUTS
#   System.Byte[]
# .OUTPUTS
#   System.Guid
# .NOTES
#   Author: Chris Dent
#
#   Change log:
#     13/06/2014 - First release  
 

[CmdLetBinding()]
param(
  [Byte[]]$AttributeValue
)



return New-Object Guid (,$AttributeValue)