function ConvertFromKSADWrappedInteger {
  # .SYNOPSIS
  #   Convert from a wrapped Int32 integer to UInt32.
  # .DESCRIPTION
  #   Internal use only.
  # .PARAMETER AttributeValue
  #   The value to unwrap. If a non-negative value is passed it is returned without modification.
  # .INPUTS
  #   System.Int32
  # .OUTPUTS
  #   System.UInt32
  # .EXAMPLE
  #   ConvertFromKSADWrappedInteger -94102
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
  
  if ($AttributeValue -lt 0 -and $AttributeValue.GetType() -eq [Int32]) {
    return [UInt32]($AttributeValue + [Math]::Pow(2, 32))
  } else {
    return $AttributeValue
  }
}