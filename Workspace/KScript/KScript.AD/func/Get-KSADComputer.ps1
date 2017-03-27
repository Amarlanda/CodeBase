function Get-KSADComputer {
  # .SYNOPSIS
  #   Get computer objects from AD.
  # .DESCRIPTION
  #   Get-KSADComputer gets computer from the default naming context.
  # .PARAMETER ANR
  #   Use Ambiguous Name Resolution to attempt to find the name in the directory.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified serverless binding is used via the site-aware DC locator process. ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER CreatedAfter
  #   Search for objects created after the specified time.
  # .PARAMETER CreatedBefore
  #   Search for objects created before the specified time.
  # .PARAMETER CreatedOn
  #   Search for objects created during the specified day (00:00:00 to 23:59:59).
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .PARAMETER Enabled
  #   Search for enabled Active Directory accounts.
  # .PARAMETER Disabled
  #   Search for disabled Active Directory accounts.
  # .PARAMETER Identity
  #   An objectGUID or DistinguishedName which can be used to uniquely identify an account across a forest.
  # .PARAMETER Name
  #   The name of the computer to find.
  # .PARAMETER OperatingSystem
  #   Search using Operating System name.
  # .PARAMETER OperatingSystemServicePack
  #   Search using Operating System service pack version.
  # .PARAMETER Properties
  #   Properties which should be returned by the searcher (instead of the default set).
  # .PARAMETER SamAccountName
  #   Search based on the specified SamAccountName.
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
  #   KScript.AD.Computer
  # .EXAMPLE
  #   Get-KSADComputer
  # .EXAMPLE
  #   Get-KSADComputer -ComputerName RemoteServer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     11/12/2014 - Chris Dent - Added Cluster parameter.
  #     04/08/2014 - Chris Dent - Offloaded identity handling to ConvertFromKSADIdentity.
  #     18/07/2014 - Chris Dent - Added support for ANR. Merged ByLdapFilter and ByMergedFilter parameter sets.
  #     27/06/2014 - Chris Dent - Added input pipeline. Added filters for CreatedBefore, CreatedOn, CreatedAfter, Enabled, Disabled, OperatingSystem and OperatingSystemServicePack.
  #     18/06/2014 - Chris Dent - First release
  
  [CmdLetBinding(DefaultParameterSetName = 'ByMergedFilter')]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByIdentity')]
    [Object]$Identity,

    [Parameter(Position = 1, ParameterSetName = 'ByMergedFilter')]
    [String]$ANR,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [String]$Name,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [String]$SamAccountName,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [String]$OperatingSystem,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [String]$OperatingSystemServicePack,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$Cluster,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$Enabled,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$Disabled,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateScript( { Get-Date $_ } )]
    [Object]$CreatedBefore,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateScript( { Get-Date $_ } )]
    [Object]$CreatedAfter,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateScript( { Get-Date $_ } )]
    [Object]$CreatedOn,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [String]$LdapFilter,
    
    [ValidatePattern('^(?:(?:OU|CN|DC)=[^=]+,)*DC=[^=]+$')]
    [String]$SearchRoot,
    
    [DirectoryServices.SearchScope]$SearchScope = [DirectoryServices.SearchScope]::Subtree,
  
    [String[]]$Properties,
    
    [ValidateRange(0, 1000)]
    [Int32]$SizeLimit = 100,

    [Switch]$UseGC,

    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  begin {
    if (($Enabled -and $Disabled) -or $CreatedOn -and ($CreatedBefore -or $CreatedAfter)) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "Invalid parameter combination."),
        "ArgumentException",
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $Name)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
  }
  
  process {
    $Params = @{}
    $PSBoundParameters.Keys |
      Where-Object { $_ -in (Get-KSCommandParameters Get-KSADObject -ParameterNamesOnly) } |
      ForEach-Object {
        $Params.Add($_, $PSBoundParameters[$_])
      }

    switch ($pscmdlet.ParameterSetName) {
      'ByIdentity' {
        $LdapFilter = ConvertFromKSADIdentity $Identity
        break
      }
      'ByMergedFilter' {
        $LdapFilterParts = "(objectClass=computer)", "(objectCategory=computer)"
        
        if ($LdapFilter)                 { $LdapFilterParts += $LdapFilter }
        if ($ANR)                        { $LdapFilterParts += "(anr=$ANR)" }
        if ($Name)                       { $LdapFilterParts += "(name=$Name)" }
        if ($SamAccountName)             { $LdapFilterParts += "(sAMAccountName=$SamAccountName)" }
        if ($OperatingSystem)            { $LdapFilterParts += "(operatingSystem=$OperatingSystem)" }
        if ($OperatingSystemServicePack) { $LdapFilterParts += "(operatingSystemServicePack=$OperatingSystemServicePack)" }
        if ($Cluster)                    { $LdapFilterParts += "(servicePrincipalName=MSClusterVirtualServer*)" }
        if ($Enabled)                    { $LdapFilterParts += "(!userAccountControl:1.2.840.113556.1.4.803:=2)" }
        if ($Disabled)                   { $LdapFilterParts += "(userAccountControl:1.2.840.113556.1.4.803:=2)" }
        if ($CreatedOn)                  { $CreatedBefore = (Get-Date $CreatedOn).Date.AddDays(1).AddSeconds(-1); $CreatedAfter = (Get-Date $CreatedOn).Date; }
        if ($CreatedBefore)              { $LdapFilterParts += "(whenCreated<=$((Get-Date $CreatedBefore).ToString('yyyyMMddHHmmss.0Z')))" }
        if ($CreatedAfter)               { $LdapFilterParts += "(whenCreated>=$((Get-Date $CreatedAfter).ToString('yyyyMMddHHmmss.0Z')))" }

        $LdapFilter = "(&$($LdapFilterParts -join ''))"
      }
    }

    if ($LdapFilter) {
      if ($Params.Contains("LdapFilter")) {
        $Params["LdapFilter"] = $LdapFilter
      } else {
        $Params.Add("LdapFilter", $LdapFilter)
      }
    
      Get-KSADObject @Params | ForEach-Object {
        $_.PSObject.TypeNames.Add("KScript.AD.Computer")

        $_
      }
    }
  }
}