function Get-KSADRootDSE {
  # .SYNOPSIS
  #   Get the RootDSE node.
  # .DESCRIPTION
  #   Get the RootDSE node from the current diretory, or the  directory running on the specified computer.
  # .PARAMETER ComputerName
  #   A ComputerName may be specified if required. If ComputerName is not specified the DCLocator algorithm will attempt to find a suitable Domain Controller.
  # .PARAMETER Credential
  #   By default, Get-KPMGADRootDSE executes with the privileges of the current user. Alternative credentials may be supplied if required.
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PsCredential
  # .OUTPUTS
  #   KScript.AD.RootDSE
  # .EXAMPLE
  #   Get-KSADRootDSE
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     04/06/2014 - Chris Dent - First release  
  
  [CmdLetBinding()]
  param(
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  $DirectoryEntry = NewKSADDirectoryEntry -DirectoryPath "LDAP://RootDSE" @psboundparameters
  
  if ($DirectoryEntry) {
    $RootDSE = ConvertFromKSADPropertyCollection $DirectoryEntry.Properties
    $RootDSE.PSObject.TypeNames.Add("KScript.AD.RootDSE")
   
    return $RootDSE
  }
}