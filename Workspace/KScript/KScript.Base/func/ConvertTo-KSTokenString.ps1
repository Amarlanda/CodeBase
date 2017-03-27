function ConvertTo-KSTokenString {
  # .SYNOPSIS
  #   Convert an object to string of text tokens; property/value pairs.
  # .DESCRIPTION
  #   Dot NET objects can consume large amounts of RAM. Memory usage can be traded for CPU load by converting objects to and from primitive types such as a string.
  #
  #    Token strings are returned in the form (PropertyName:ValueType:Value).
  # .PARAMETER Object
  #   An input object which should be represented as a string.
  # .INPUTS
  #   System.Object
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   Get-Process PowerShell | Select-Object Name, ID | ConvertTo-KSTokenString
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     26/06/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [Object]$Object
  )
  
  process {
    ($Object.PSObject.Properties | ForEach-Object { "($($_.Name):$($_.TypeNameOfValue):$($_.Value))" }) -join ''
  }
}