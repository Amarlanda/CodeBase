function NewKSWmiParams {
  # .SYNOPSIS
  #   Creates a new parameter hash table based on $psboundparameters.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   NewKSWmiParams creates a splatting variable from two input parameters.
  #
  #   NewKSWmiParams allows parameter overloading (does not use CmdLetBinding). Additional parameters are silently dropped.
  # .PARAMETER ComputerName
  #   A ComputerName to use with Get-WmiObject.
  # .PARAMETER Credential
  #   Credentials to use for the WMI operation. By default the query is executed using the callers account.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.Collections.HashTable
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     10/10/2014 - Chris Dent - First release.

  param(
    [String]$ComputerName = (hostname),
    
    [PSCredential]$Credential
  )

  $WmiParams = @{"ComputerName" = $ComputerName}
  if ($psboundparameters.ContainsKey('Credential')) {
    $WmiParams.Add('Credential', $Credential)
  }
  
  return $WmiParams
}