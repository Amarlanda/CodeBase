function Add-KSADGroupMember {
  # .SYNOPSIS
  #   Add a member to the specified group.
  # .DESCRIPTION
  #   Add-KSADGroupMember attempts to add a member to the specified Active Directory group.
  # .PARAMETER Identity
  #   The identity (distinguishedName, objectGUID or userPrincipalName) of the group to modify.
  # .PARAMETER Member
  #   The members which should be added to the group.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Add-KSADGroupMember -Identity "CN=Group,OU=somewhere,DC=domain,DC=example" -Member "Member1@domain.example"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     22/09/2014 - Chris Dent - First release.

  [CmdLetBinding(DefaultParameterSetName = 'StandardSearch')]
  param(
    [Parameter(ParameterSetName = 'StandardSearch', ValueFromPipelineByPropertyName = $true)]
    [String]$Identity,
    
    [String[]]$Member
  )

  process {
    $IdentityLdapFilter = ConvertFromKSADIdentity $Identity
  
    $Params = @{}
    if ($psboundparameters.ContainsKey("ComputerName")) { $Params.Add("ComputerName", $ComputerName) }
    if ($psboundparameters.ContainsKey("Credential"))   { $Params.Add("Credential", $Credential) }
    
    $KSADGroup = Get-KSADGroup -LdapFilter $IdentityLdapFilter @Params
    $ADGroup $KSADGroup.GetDirectoryEntry()
    
    $Member | ForEach-Object {
      if ($_ -notmatch '^CN=') {
        $LdapFilter = ConvertFromKSADIdentity $_
        $_ = Get-KSADObject -LdapFilter $LdapFilter @Params | Select-Object -ExpandProperty DistinguishedName
      }
      
      if ($_ -match '^CN=') {
        try {
          $Group.Add("LDAP://$_")
        } catch {
          
        }
      }
    }
  }
}