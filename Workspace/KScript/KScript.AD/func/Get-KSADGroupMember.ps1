function Get-KSADGroupMember {
  # .SYNOPSIS
  #   Get all members of a group.
  # .DESCRIPTION
  #   Get-KSADGroupMember executes a query against Active Directory for all the groups an object belongs to.
  #
  #   Get-KSADGroupMember shares parameters with Get-KSADObject.
  #
  #   Indirect membership is chased using the LDAP_MATCHING_RULE_IN_CHAIN operator.
  # .PARAMETER Identity
  #   The identity (distinguishedName, objectGUID or userPrincipalName) of the object whose membership to list.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.AD.Object
  # .EXAMPLE
  #   Get-KSADGroup SomeGroup | Get-KSADGroupMember
  # .EXAMPLE
  #   Get-KSADGroup SomeGroup | Get-KSADGroupMember -Indirect
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/12/2014 - Chris Dent - BugFix: LDAP filter parameter passthru.
  #     19/08/2014 - Chris Dent - BugFix: Invalid default parameter set name.
  #     05/08/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'StandardSearch')]
  param(
    [Parameter(ParameterSetName = 'StandardSearch', ValueFromPipelineByPropertyName = $true)]
    [String]$Identity,
    
    [Switch]$Indirect
  )

  dynamicparam {
    $ParamDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary

    Get-KSCommandParameters Get-KSADObject | ForEach-Object {
      $DynamicParameter = New-Object Management.Automation.RuntimeDefinedParameter($_.Name, $_.ParameterType, $_.Attributes)
      $ParamDictionary.Add($_.Name, $DynamicParameter)
    }
    
    return $ParamDictionary
  }
  
  process {
    $IdentityLdapFilter = ConvertFromKSADIdentity $Identity
  
    $Params = @{}
    if ($psboundparameters.ContainsKey("ComputerName")) { $Params.Add("ComputerName", $ComputerName) }
    if ($psboundparameters.ContainsKey("Credential"))   { $Params.Add("Credential", $Credential) }
    
    $GroupDN = Get-KSADGroup -LdapFilter $IdentityLdapFilter @Params | Select-Object -ExpandProperty distinguishedName
    
    if ($GroupDN) {
      if ($Indirect) {
        $Operator = ":%LDAP_CHAIN%:="
      } else {
        $Operator = "="
      }
      
      if ($psboundparameters.ContainsKey("LdapFilter")) {
        $LdapFilter = "(&(memberOf$Operator$GroupDN)$($psboundparameters['LdapFilter']))"
      } else {
        $LdapFilter = "(memberOf$Operator$GroupDN)"
      }
      
      $psboundparameters.Keys |
        Where-Object { $_ -notin 'Identity', 'Indirect', 'LdapFilter' } |
        ForEach-Object { $Params.Add($_, $psboundparameters[$_]) }
      
      Get-KSADObject -LdapFilter $LdapFilter @Params | ForEach-Object {
        $_.PSObject.TypeNames.Add("KScript.AD.Object")

        $_
      }
    }
  }
}