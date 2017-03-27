function Get-KSADDomainPasswordPolicy {
  # .SYNOPSIS
  #   Get the domain password policy.
  # .DESCRIPTION
  #   Get-KSADDomainPasswordPolicy gets properties associated with the domain password policy from the domain.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSADDomainPasswordPolicy uses serverless binding via the site-aware DC locator process. ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   KScript.AD.DomainPasswordPolicy
  # .EXAMPLE
  #   Get-KSADDomainPasswordPolicy
  # .EXAMPLE
  #   Get-KSADDomainPasswordPolicy -ComputerName RemoteServer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     16/06/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )
  
  $Domain = Get-KSADObject -LdapFilter "(objectClass=domainDNS)" @PSBoundParameters
  
  $DomainPasswordPolicy = New-Object PSObject -Property ([Ordered]@{
    DistinguishedName                       = $Domain.distinguishedname
    EnforcePasswordHistory                  = $Domain.pwdhistorylength
    MaximumPasswordAge                      = $Domain.maxpwdage
    MinimumPasswordAge                      = $Domain.minpwdage
    MinimumPasswordLength                   = $Domain.minpwdlength
    PasswordMustMeetComplexityRequirements  = $false
    StorePasswordsUsingReversibleEncryption = $false
    PasswordProperties                      = $Domain.pwdproperties
    LockoutDuration                         = $Domain.lockoutduration
    LockoutThreshold                        = $Domain.lockoutthreshold
    LockoutResetCounterAfter                = $Domain.lockoutobservationwindow
  })
  $DomainPasswordPolicy.PSObject.TypeNames.Add("KPMG.AD.DomainPasswordPolicy")
  
  if ($Domain.pwdproperties -band [KScript.AD.pwdProperties]::Complex) {
    $DomainPasswordPolicy.PasswordMustMeetComplexityRequirements = $true
  }
  if ($Domain.pwdproperties -band [KScript.AD.pwdProperties]::StoreClearText) {
    $DomainPasswordPolicy.StorePasswordsUsingReversibleEncryption = $true
  }
  
  return $DomainPasswordPolicy
}