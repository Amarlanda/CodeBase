function Get-KSCimInstance {
  # .SYNOPSIS
  #   Get a CimInstance using the DCOM protocol.
  # .DESCRIPTION
  #   Get-KSCimInstance is a small wrapper around the native CmdLet which switches the protocol used to DCOM to better simulate Get-WmiObject.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER ClassName
  #   The WMI class to query.
  # .PARAMETER Credential
  #   By default current user is used, alternate credentials may be specified if required.
  # .PARAMETER Filter
  #   A WQL filter to use for the WMI query.
  # .PARAMETER Namespace
  #   A WMI namespace, by default root/cimv2 is used.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.CimInstance
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     14/01/2015 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ClassName,
    
    [String]$Namespace,
    
    [String]$Filter,
    
    [String]$ComputerName = $env:ComputerName,
    
    [PSCredential]$Credential
  )

  begin {
    $CimSessionOptions = New-CimSessionOption -Protocol Dcom -Culture (Get-Culture) -UICulture (Get-Culture)
  }
  
  process {
    $SessionParams = @{ComputerName = $ComputerName}
    if ($psboundparameters.ContainsKey("Credential")) { $SessionParams.Add("Credential", $Credential) }
    $CimSession = New-CimSession @SessionParams -SessionOption $CimSessionOptions
    
    if ($?) {
      $GetParams = @{
        ClassName = $ClassName
        OperationTimeoutSec = 30
        CimSession = $CimSession
      }
      if ($psboundparameters.ContainsKey("Namespace")) { $GetParams.Add("Namespace", $Namespace) }
      if ($psboundparameters.ContainsKey("Filter")) { $GetParams.Add("Filter", $Filter) }
      
      Get-CimInstance @GetParams
    }
  }
}