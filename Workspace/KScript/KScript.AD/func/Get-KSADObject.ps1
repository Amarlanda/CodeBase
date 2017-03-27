function Get-KSADObject {
  # .SYNOPSIS
  #   Get objects from Active Directory using System.DirectoryServices (ADSI).
  # .DESCRIPTION
  #   Get-KPMGADObject uses System.DirectoryServices.DirectorySearcher to get objects from Active Directory.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSADObject uses serverless binding via the site-aware DC locator process. ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .PARAMETER LdapFilter
  #   An LDAP filter to use with the search. The filter (objectClass=*) is used by default.
  # .PARAMETER Properties
  #   Properties which should be returned by the searcher (instead of the default set).
  # .PARAMETER ReferralChasing
  #   Get-KPMGADObject follows external referrals by default.
  # .PARAMETER SearchRoot
  #   The starting point for the search as a distinguishedName.
  # .PARAMETER SearchScope
  #   SearchScope defaults to SubTree but may be set to OneLevel or None.
  # .PARAMETER SizeLimit
  #   The maximum number of results to be returned by the search. If SizeLimit is set, Paging is disabled. SizeLimit cannot be set higher than 1000. Setting SizeLimit to 0 returns all results.
  # .PARAMETER UseGC
  #   Use a Global Catalog to execute this search.
  # .INPUTS
  #   System.DirectoryServices.ReferralChasingOption
  #   System.DirectoryServices.SearchScope
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   KScript.AD.Object
  # .EXAMPLE
  #   Get-KSADObject -LdapFilter "(samAccountName=$env:Username)"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     26/06/2014 - Chris Dent - Added DirectorySynchronization support.
  #     04/06/2014 - Chris Dent - First release

  [CmdLetBinding(DefaultParameterSetName = 'StandardSearch')]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$LdapFilter = "(objectClass=*)",
    
    [Parameter(ParameterSetName = 'StandardSearch')]
    [ValidatePattern('^(?:(?:OU|CN|DC)=[^=]+,)*DC=[^=]+$')]
    [String]$SearchRoot,
    
    [DirectoryServices.SearchScope]$SearchScope = [DirectoryServices.SearchScope]::Subtree,
    
    [String[]]$Properties,
    
    [Parameter(ParameterSetName = 'StandardSearch')]
    [ValidateRange(0, 1000)]
    [Int32]$SizeLimit = 100,
    
    [DirectoryServices.ReferralChasingOption]$ReferralChasing = [DirectoryServices.ReferralChasingOption]::External,

    [Switch]$UseGC,

    [Parameter(Mandatory = $true, ParameterSetName = 'DirectorySynchronization')]
    [Switch]$DirSync,
    
    [Parameter(ParameterSetName = 'DirectorySynchronization')]
    [String]$DirSyncCookie = "DirSyncCookie.dat",
    
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  $DirectoryEntryParams = @{}
  
  if ($ComputerName) { $DirectoryEntryParams.Add("ComputerName", $ComputerName) }
  if ($Credential) { $DirectoryEntryParams.Add("Credential", $Credential) }
  
  # Search root must be defined to allow instantiation of a System.DirectoryServices.DirectoryEntry object using GC:// instead of LDAP://
  if ($UseGC -and -not $SearchRoot) {
    # Attempt to discover the default suffix for the current client.
    $SearchRoot = Get-KSADRootDSE @DirectoryEntryParams | Select-Object -ExpandProperty DefaultNamingContext
    $DirectoryPath = "GC://$SearchRoot"
  } elseif ($UseGC -and $SearchRoot) {
    $DirectoryPath = "GC://$SearchRoot"
  } elseif ($SearchRoot) {
    $DirectoryPath = "LDAP://$SearchRoot"
  }
  if ($DirectoryPath) { $DirectoryEntryParams.Add("DirectoryPath", $DirectoryPath) }
  
  $DirectoryEntry = NewKSADDirectoryEntry @DirectoryEntryParams
  
  if ($DirectoryEntry) {
    # Expand any terms used in the LDAP filter
    $LdapFilter = Expand-KSADLdapFilter $LdapFilter

    $Searcher = New-Object DirectoryServices.DirectorySearcher($DirectoryEntry, $LdapFilter)
    $Searcher.SearchScope = $SearchScope
    $Searcher.ReferralChasing = $ReferralChasing
    
    if ($Properties) {
      # objectGUID will always be returned so it can be written to identity.
      if ("objectGUID" -notin $Properties) {
        $Properties += "objectGUID"
      }
      $Searcher.PropertiesToLoad.AddRange($Properties)
    }
    
    $Searcher.SizeLimit = $SizeLimit
    if ($SizeLimit -eq 0) {
      $Searcher.PageSize = 1000
    }

    if ($DirSync) {
      if (Test-Path $DirSyncCookie -PathType Leaf) {
        $Cookie = Get-Content $DirSyncCookie -Encoding Byte -Raw
        $DirectorySynchronization = New-Object DirectoryServices.DirectorySynchronization([DirectoryServices.DirectorySynchronizationOptions]::ObjectSecurity, $Cookie)
        } else {
        $DirectorySynchronization = New-Object DirectoryServices.DirectorySynchronization([DirectoryServices.DirectorySynchronizationOptions]::ObjectSecurity)
      }
    
      $Searcher.DirectorySynchronization = $DirectorySynchronization
    }
    
    $i = 0
    
    $Searcher.FindAll() | ForEach-Object {
      $i++
    
      $Object = ConvertFromKSADPropertyCollection $_.Properties
      if ($myinvocation.CommandOrigin -eq 'Runspace') {
        $Object.PSObject.TypeNames.Add("KScript.AD.Object")
      }

      if ($DirectoryEntry.PSBase.PrincipalContext) {
        # Property: PrincipalContext
        $Object | Add-Member PrincipalContext -MemberType NoteProperty -Value $DirectoryEntry.PSBase.PrincipalContext
        # Method: GetAccountManagementPrincipal
        $Object | Add-Member GetAccountManagementPrincipal -MemberType ScriptMethod -Value {
          if ($this.Type -in 'Computer', 'Group', 'User') {
            $("DirectoryServices.AccountManagement.$($this.Type)Principal" -as [Type])::FindByIdentity($this.PrincipalContext, [DirectoryServices.AccountManagement.IdentityType]::Guid, $this.objectGUID)
          }
        }
      }

      # Property: SearchResult
      $Object | Add-Member SearchResult -MemberType NoteProperty -Value $_
      # Method: GetDirectoryEntry - Expose SearchResult.GetDirectoryEntry on the base object.
      $Object | Add-Member GetDirectoryEntry -MemberType ScriptMethod -Value {
        $this.SearchResult.GetDirectoryEntry()
      }
     
      $Object
    }
    if ($i -ge $SizeLimit -and $SizeLimit -ne 0 -and -not $DirSync) {
      Write-Warning "More results may be available than the size limit of $SizeLimit."
    }
    
    if ($Searcher.DirectorySynchronization) {
      Set-Content $DirSyncCookie -Value ($Searcher.DirectorySynchronization.GetDirectorySynchronizationCookie()) -Encoding Byte
    }
  }
}