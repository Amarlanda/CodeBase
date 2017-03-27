function Get-KSADMemberOf {
  # .SYNOPSIS
  #   Get all groups an object belongs to.
  # .DESCRIPTION
  #   Get-KSADMemberOf executes a query against Active Directory for all the groups an object belongs to.
  #
  #   Get-KSADMemberOf shares parameters with Get-KSADGroup with the exception of Identity.
  #
  #   Indirect membership is chased using the LDAP_MATCHING_RULE_IN_CHAIN operator.
  # .PARAMETER Identity
  #   The identity (distinguishedName or objectGUID) of the object whose membership to list.
  # .INPUTS
  #   System.Object
  # .OUTPUTS
  #   KScript.AD.Group
  # .EXAMPLE
  #   Get-KSADUser SomeUser | Get-KSADMemberOf
  # .EXAMPLE
  #   Get-KSADUser SomeUser | Get-KSADMemberOf -Indirect
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/12/2014 - Chris Dent - BugFix: LDAP filter parameter passthru.
  #     29/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'ByMergedFilter')]
  param(
    [Parameter(ParameterSetName = 'ByMergedFilter', ValueFromPipelineByPropertyName = $true)]
    [String]$Identity,
    
    [Switch]$Indirect
  )

  dynamicparam {
    $ParamDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary

    Get-KSCommandParameters Get-KSADGroup | Where-Object Name -ne Identity | ForEach-Object {
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
    
    $ObjectDN = Get-KSADObject -LdapFilter $IdentityLdapFilter @Params | Select-Object -ExpandProperty distinguishedName
    
    if ($ObjectDN) {
      if ($Indirect) {
        $Operator = ":%LDAP_CHAIN%:="
      } else {
        $Operator = "="
      }
      
      if ($psboundparameters.ContainsKey("LdapFilter")) {
        $LdapFilter = "(&(member$Operator$ObjectDN)$($psboundparameters['LdapFilter']))"
      } else {
        $LdapFilter = "(member$Operator$ObjectDN)"
      }
      
      $psboundparameters.Keys |
        Where-Object { $_ -notin 'Identity', 'Indirect' } |
        ForEach-Object { $Params.Add($_, $psboundparameters[$_]) }
      
      Get-KSADGroup -LdapFilter $LdapFilter @Params
    }
  }
}