function ConvertFrom-KSSID {
  # .SYNOPSIS
  #   Attempt to convert a SID (string or object) to Security.Principal.NTAccount
  # .DESCRIPTION
  #   ConvertFrom-KSSID calls the Translate method in an attempt to convert a SID (object or string) to an NTAccount.
  #
  #   ConvertFrom-KSSID may be used to attempt to resolve SIDs across a forest, and address trusts.
  #
  #   The result of SID resolution is relative to the 
  # .PARAMETER SecurityIdentifier
  #   The security identifier to convert, acceptable values include domain SIDs or SIDs for local accounts or well-known SIDs.
  # .INPUTS
  #   System.Security.Principal.SecurityIdentifier
  # .OUTPUTS
  #   System.Security.Principal.NTAccount
  # .EXAMPLE
  #   ConvertFrom-KSSID "S-1-5-20"
  #
  #   Return the built-in security principal "NT AUTHORITY\NETWORK SERVICE".
  # .EXAMPLE
  #   ConvertFrom-KSSID "S-1-5-21-1965243242-631715425-1848903544-500"
  #
  #   Return the default administrator account for the domain identified by S-1-5-21-1965243242-631715425-1848903544 (objectSID for domainDNS object).
  # .EXAMPLE
  #   $DomainSID = Get-KSADObject -LdapFilter "(objectClass=domainDNS)" | Select-Object -ExpandProperty objectSID
  #   [Enum]::GetValues([Security.Principal.WellKnownSidType]) | ForEach-Object {
  #     try { $SID = New-Object Security.Principal.SecurityIdentifier($_, $DomainSID) } catch { }
  #
  #     if ($SID) {
  #       $Name= (ConvertFrom-KSSID $SID -ErrorAction SilentlyContinue).Value
  #    
  #       New-Object PSObject -Property ([Ordered]@{
  #         WellKnownType = $_.ToString()
  #         Name          = (ConvertFrom-KSSID $SID -ErrorAction SilentlyContinue).Value
  #         SID           = $SID.Value
  #       })
  #     }
  #   }
  #
  #   List all WellKnownSidTypes, create a SID from the well known type (specific to the current domain), display the name of the account using that SID.
  #
  #   This method will display all default accounts (such as Administrator) even if the account has been renamed.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     06/08/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias('objectSID')]
    [Security.Principal.SecurityIdentifier]$SecurityIdentifier
  )

  process {
    $SecurityIdentifier.Translate([Security.Principal.NTAccount])
  }
}