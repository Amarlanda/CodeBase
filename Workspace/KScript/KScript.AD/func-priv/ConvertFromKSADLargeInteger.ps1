function ConvertFromKSADLargeInteger {
  # .SYNOPSIS
  #   Convert IADSLargeInteger to UInt64.
  # .DESCRIPTION
  #   Internal use only.
  # .PARAMETER AttributeValue
  #   A IADSLargeInteger ComObject.
  # .INPUTS
  #   System.__ComObject
  # .OUTPUTS
  #   System.UInt64
  # .EXAMPLE
  #   ConvertFromKSADLargeInteger $DirectoryEntry.Properties['lastLogonTimestamp'][0]
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     04/08/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    $AttributeValue
  )
  
  $HighPart = ConvertFromKSADWrappedInteger ($AttributeValue.GetType().InvokeMember('HighPart', 'GetProperty', $null, $AttributeValue, $null))
  $LowPart = ConvertFromKSADWrappedInteger ($AttributeValue.GetType().InvokeMember('LowPart', 'GetProperty', $null, $AttributeValue, $null))

  return (([UInt64]$HighPart -shl 32) + [UInt64]$LowPart)
}