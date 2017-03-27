function GetKSLyncPolicySearchExpression {
  # .SYNOPSIS
  #   Generate the parameter set and Where-Object filter elements from a KS Lync policy.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   The policy expression is shared between Update-KSLyncUserPolicy and Test-KSLyncUserPolicy. This exists to avoid repetition of the algorithm.
  # .PARAMETER KSLyncPolicy
  #   An individual KS Lync policy.
  # .PARAMETER UserPrincipalName
  #   Used by Test-KSLyncUserPolicy, includes the UserPrincipalName in the LDAP filter generated by this function.
  # .INPUTS
  #   KScript.Lync.Policy
  # .OUTPUTS
  #   System.Hashtable
  #   System.Management.Automation.ScriptBlock
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/08/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.Lync.Policy' } )]
    $KSLyncPolicy,
    
    [String]$UserPrincipalName
  )
  
  $Params = @{}; $WhereStatementParts = @('$_')
    
  $KSLyncPolicy.Filters | ForEach-Object {
    $Filter = $_
    if ($Filter.Value) { $Filter.Value = $Filter.Value.Trim() }
    if ($Filter.Pattern) { $Filter.Pattern = $Filter.Pattern.Trim() }
    
    switch ($_.Type) {
      'SearchRoot' {
        # CsAdUser does not support the use of the domain root for the OU parameter. If the SearchRoot begins with a domain component it will be 
        # added to the PatternMatch set. The filter is limited to a single domain by forcing it to fail a match if any domain components 
        # appear before the SearchRoot.
        if ($Filter.Value -match '^DC=') {
          $WhereStatementParts += "`$_.distinguishedName -match '(?<!,DC=.+),$($Filter.Value)$'"
        } else {
          $Params.Add("OU", $Filter.Value)
        }
        break
      }
      'LdapFilter' {
        if ($Params.Contains("LdapFilter")) {
          Write-Error "LdapFilter cannot appear more than once in a policy"
        } else {
          $Params.Add("LdapFilter", $Filter.Value)
        }
        break
      }
      'PatternMatch' {
        $WhereStatementParts += "`$_.$($Filter.Property) -match '$($Filter.Pattern)'"
        break
      }
    }
  }

  if ($Params.Contains("LdapFilter")) {
    if ($UserPrincipalName) {
      $Params["LdapFilter"] = "(&(userPrincipalName=$UserPrincipalName)(msRTCSIP-UserEnabled=TRUE)$LdapFilter)"
    } else {
      $Params["LdapFilter"] = "(&(msRTCSIP-UserEnabled=TRUE)$LdapFilter)"
    }
  } else {
    if ($UserPrincipalName) {
      $Params.Add("LdapFilter", "(&(userPrincipalName=$UserPrincipalName)(msRTCSIP-UserEnabled=TRUE))")
    } else {
      $Params.Add("LdapFilter", "(msRTCSIP-UserEnabled=TRUE)")
    }
  }
  $WhereStatement = [ScriptBlock]::Create(($WhereStatementParts -join ' -and '))

  New-Object PSObject -Property ([Ordered]@{
    Parameters     = $Params
    WhereStatement = $WhereStatement
  })
}