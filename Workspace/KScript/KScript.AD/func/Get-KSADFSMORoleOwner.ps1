function Get-KSADFSMORoleOwner {
  # .SYNOPSIS
  #   Get the FSMO role owners.
  # .DESCRIPTION
  #   Get the FSMO (flexible single master operations) owners from an Active Directory domain.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSADOrganizationalUnit uses serverless binding via the site-aware DC locator process. ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   KScript.AD.FSMORoleOwner
  # .EXAMPLE
  #   Get-KSADFSMORoleOwner
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     22/09/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )
  
  $RootDSE = Get-KSADRootDSE @psboundparameters
  $LookupCache = @{}
  
  @(
    [Ordered]@{Role = 'DomainNamingMaster';   Filter = '(&(objectClass=crossRefContainer)(fSMORoleOwner=*))';    SearchRoot = 'configurationNamingContext'}
    [Ordered]@{Role = 'InfrastructureMaster'; Filter = '(&(objectClass=infrastructureUpdate)(fSMORoleOwner=*))'; SearchRoot = 'defaultNamingContext'}
    [Ordered]@{Role = 'PDCEmulator';          Filter = '(&(objectClass=domainDNS)(fsmoRoleOwner=*))';            SearchRoot = 'defaultNamingContext'} 
    [Ordered]@{Role = 'RIDMaster';            Filter = '(&(objectClass=riDManager)(fsmoRoleOwner=*))';           SearchRoot = 'defaultNamingContext'}
    [Ordered]@{Role = 'SchemaMaster';         Filter = '(&(objectClass=dMD)(fSMORoleOwner=*))';                  SearchRoot = 'schemaNamingContext'}
  ) | ForEach-Object {
    $Role = New-Object PSObject -Property $_
    
    $RoleOwner = Get-KSADObject -LdapFilter $Role.Filter -SearchRoot $RootDSE.($Role.SearchRoot) -Properties fsmoRoleOwner @psboundparameters
    if ($LookupCache.Contains($RoleOwner.fsmoRoleOwner)) {
      $DnsHostName = $LookupCache[$RoleOwner.fsmoRoleOwner]
    } else {
      $FsmoRoleOwnerDN = $RoleOwner.fsmoRoleOwner -replace '^CN=NTDS Settings,'
      $DnsHostName = Get-KSADObject -LdapFilter "(objectClass=server)" -SearchRoot $FsmoRoleOwnerDN -SearchScope Base -Properties dnsHostName @psboundparameters |
        Select-Object -ExpandProperty DnsHostName
      $LookupCache.Add($RoleOwner.fsmoRoleOwner, $DnsHostName)
    }
    
    New-Object PSObject -Property ([Ordered]@{
      Role  = $Role.Role
      Owner = $DnsHostName
    })
  }
}