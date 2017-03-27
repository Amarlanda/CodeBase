function Get-KSADDomain {
  # .SYNOPSIS
  #   Get domain objects from AD.
  # .DESCRIPTION
  #   Get-KSADDomain gets domain from a domain naming context.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSADOrganizationalUnit uses serverless binding via the site-aware DC locator process. ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .PARAMETER Name
  #   The name of the Domain to find.
  # .PARAMETER SizeLimit
  #   The maximum number of results to be returned by the search. If SizeLimit is set, Paging is disabled. SizeLimit cannot be set higher than 1000. Setting SizeLimit to 0 returns all results.
  # .PARAMETER Properties
  #   Properties which should be returned by the searcher (instead of the default set).
  # .PARAMETER SearchRoot
  #   The starting point for the search as a distinguishedName.
  # .PARAMETER SearchScope
  #   SearchScope defaults to SubTree but may be set to OneLevel or None.
  # .PARAMETER SizeLimit
  #   The maximum number of results to be returned by the search. If SizeLimit is set, Paging is disabled. SizeLimit cannot be set higher than 1000. Setting SizeLimit to 0 returns all results.
  # .PARAMETER UseGC
  #   Use a Global Catalog to execute this search.
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   KScript.AD.OrganizationalUnit
  # .EXAMPLE
  #   Get-KSADOrganizationalUnit
  # .EXAMPLE
  #   Get-KSADOrganizationalUnit -ComputerName RemoteServer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     02/09/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [String]$Name,
  
    [ValidatePattern('^(?:DC=[^=]+,)*DC=[^=]+$')]
    [String]$SearchRoot,
    
    [DirectoryServices.SearchScope]$SearchScope = [DirectoryServices.SearchScope]::Subtree,
  
    [String[]]$Properties,
    
    [ValidateRange(0, 1000)]
    [Int32]$SizeLimit = 100,

    [Switch]$UseGC,
    
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  $Params = @{}
  $PSBoundParameters.Keys |
    Where-Object { $_ -in (Get-KSCommandParameters Get-KSADObject -ParameterNamesOnly) } |
    ForEach-Object {
      $Params.Add($_, $PSBoundParameters[$_])
    }
  
  $LdapFilter = "(&(objectClass=domain)(objectCategory=domain))"
  if ($Name) {
    $LdapFilter = "(&(name=$Name)(objectClass=domain)(objectCategory=domain))"
  }
  $Params.Add("LdapFilter", $LdapFilter)
  
  Get-KSADObject @Params | ForEach-Object {
    $_.PSObject.TypeNames.Add("KScript.AD.Domain")
    
    $_
  }
}