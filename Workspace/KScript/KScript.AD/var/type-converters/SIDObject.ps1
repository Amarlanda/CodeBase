# .SYNOPSIS
#   Convert a byte array to System.Security.Principal.SecurityIdentifier.
# .DESCRIPTION
#   Internal use only.
# .PARAMETER Value
#   The value for the attribute returned by either System.DirectoryServices.DirectoryEntry or System.DirectoryServices.SearchResult.
# .INPUTS
#   System.Byte[]
# .OUTPUTS
#   System.Security.Principal.SecurityIdentifier
# .NOTES
#   Author: Chris Dent
#
#   Change log:
#     13/06/2014 - First release  
 

[CmdLetBinding()]
param(
  [Byte[]]$AttributeValue
)

New-Object Security.Principal.SecurityIdentifier([Byte[]]$AttributeValue, 0)