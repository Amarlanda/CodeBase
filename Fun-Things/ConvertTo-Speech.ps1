function ConvertTo-Speech
{
  <#
      .SYNOPSIS
      Short Description
      .DESCRIPTION
      Detailed Description
      .EXAMPLE
      Convert-Speech
      explains how to use the command
      can be multiple lines
      .EXAMPLE
      Convert-Speech
      another example
      can have as many examples as you like
  #>
  [CmdletBinding()]
  param
  (
    [Parameter(Mandatory=$true, Position=0)]
    [System.String]
    $text,
    [Parameter(Mandatory=$false, Position=1)]
    [validateRange(-10,10)]
    $rate = 1
  )
  
  $sapi =New-Object -ComObject Sapi.spvoice
  $null = $sapi.speak($text)
}