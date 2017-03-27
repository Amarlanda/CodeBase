function Get-KSADDomainController {
  # .SYNOPSIS
  #   Get Domain Controllers from AD.
  # .DESCRIPTION
  #   Get-KSADDomainController gets Domain Controllers from the domain naming context.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSADDomainController uses serverless binding via the site-aware DC locator process. ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .PARAMETER Name
  #   The name of the Domain Controller to find.
  # .PARAMETER SizeLimit
  #   The maximum number of results to be returned by the search. If SizeLimit is set, Paging is disabled. SizeLimit cannot be set higher than 1000. Setting SizeLimit to 0 returns all results.
  # .PARAMETER Properties
  #   Properties which should be returned by the searcher (instead of the default set).
  # .PARAMETER SizeLimit
  #   The maximum number of results to be returned by the search. If SizeLimit is set, Paging is disabled. SizeLimit cannot be set higher than 1000. Setting SizeLimit to 0 returns all results.
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   KScript.AD.Computer
  # .EXAMPLE
  #   Get-KSADDomainController
  # .EXAMPLE
  #   Get-KSADDomainController -ComputerName RemoteServer
  # .NOTES
  #   Author: Chris Dent
  #   Team: Core Technologies
  #
  #   Change log:
  #     17/06/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [String]$Name,
    
    [String[]]$Properties,
    
    [ValidateRange(0, 1000)]
    [Int32]$SizeLimit = 100,
    
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  $Params = @{}
  $psboundparameters.Keys |
    Where-Object { $_ -in (Get-KSCommandParameters Get-KSADObject -ParameterNamesOnly) } |
    ForEach-Object {
      $Params.Add($_, $psboundparameters[$_])
    }
  
  $LdapFilter = "(&(objectClass=computer)(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=532480))"
  if ($Name) {
    $LdapFilter = "(&(name=$Name)(objectClass=computer)(objectCategory=computer)(userAccountControl:1.2.840.113556.1.4.803:=532480))"
  }
  $Params.Add("LdapFilter", $LdapFilter)
  
  Get-KSADObject @Params | ForEach-Object {
    $_.PSObject.TypeNames.Add("KScript.AD.Computer")
    
    $_
  }
}