function ConvertFrom-KSTokenString {
  # .SYNOPSIS
  #   Convert from a token string to an object.
  # .DESCRIPTION
  #   Dot NET objects can consume large amounts of RAM. Memory usage can be traded for CPU load by converting objects to and from primitive types such as a string.
  #  
  #    Token strings are returned in the form (PropertyName:ValueType:Value).
  # .PARAMETER TokenString
  #   An input object which should be represented as a string.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Object
  # .EXAMPLE
  #   "(Name:System.String:PowerShell)(ID:System.Int32:1234)" | ConvertFrom-KSTokenString
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     26/06/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [String]$TokenString
  )
  
  process {
    $Object = New-Object PSObject
    [RegEx]::Matches($TokenString, '\((?<PropertyName>[^:]+):(?<ValueType>[^:]*):(?<Value>[^\)]*)\)') | ForEach-Object {
      $PropertyName = $_.Groups['PropertyName'].Value
      $Value = $_.Groups['Value'].Value
      $ValueType = $_.Groups['ValueType'].Value -as [Type]
      
      if ($ValueType -and -not ($Value -is $ValueType)) {
        # Attempt to change the value type
        try { $Value = [Convert]::ChangeType($Value, $ValueType) } catch { }
      }
      Add-Member $PropertyName -MemberType NoteProperty -Value $Value -InputObject $Object
    }
    return $Object
  }
}