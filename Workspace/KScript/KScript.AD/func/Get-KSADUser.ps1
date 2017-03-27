function Get-KSADUser {
  # .SYNOPSIS
  #   Get user objects from AD.
  # .DESCRIPTION
  #   Get-KSADUser gets computer from the default naming context.
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
  #   Search for enabled Active Directory accounts. Cannot be used alongside the Disabled parameter.
  # .PARAMETER Description
  #   Search for acconts with the specified Description value.
  # .PARAMETER Disabled
  #   Search for disabled Active Directory accounts. Cannot be used alongside the Enabled parameter.
  # .PARAMETER DisplayName
  #   Search using DisplayName.
  # .PARAMETER Identity
  #   An objectGUID, DistinguishedName or UserPrincipalName which can be used to uniquely identify an account across a forest.
  # .PARAMETER LyncEnabled
  #   Search for Lync enabled accounts. Cannot be used alongside the LyncDisabled parameter.
  # .PARAMETER LyncDisabled
  #   Search for Lync disabled accounts. Cannot be used alongside the LyncEnabled parameter.
  # .PARAMETER LdapFilter
  #   Use the specified LDAP filter to search. Note: (objectClass=user)(objectCategory=person) will be added to the filter.
  # .PARAMETER physicalDeliveryOfficeName
  #   Search for accounts with the specified Office value.
  # .PARAMETER Properties
  #   Properties which should be returned by the searcher (instead of the default set).
  # .PARAMETER ProxyAddress
  #   A single address from the proxyAddresses attribute.
  # .PARAMETER SamAccountName
  #   Search based on the specified SamAccountName.
  # .PARAMETER SipAddress
  #   Search based on the specified SipAddress.
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
  #   KScript.AD.User
  # .EXAMPLE
  #   Get-KSADUser
  # .EXAMPLE
  #   Get-KSADUser -ComputerName RemoteServer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/10/2014 - Chris Dent - Added department filter.
  #     14/10/2014 - Chris Dent - Added description filter.
  #     04/08/2014 - Chris Dent - Offloaded identity handling to ConvertFromKSADIdentity.
  #     24/07/2014 - Chris Dent - Added SipAddress parameter, fixed proxyAddress parameter regex check.
  #     18/07/2014 - Chris Dent - Fixed parameter set binding for ANR.
  #     14/07/2014 - Chris Dent - Added filter for physicalDeliveryOfficeName. Merged ByLdapFilter and ByMergedFilter parameter sets.
  #     27/06/2014 - Chris Dent - First release
  
  [CmdLetBinding(DefaultParameterSetName = 'ByMergedFilter')]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true, ParameterSetName = 'ByIdentity')]
    [Object]$Identity,

    [Parameter(Position = 1, ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$ANR,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Get-Date $_ } )]
    [Object]$CreatedAfter,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Get-Date $_ } )]
    [Object]$CreatedBefore,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Get-Date $_ } )]
    [Object]$CreatedOn,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$department,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$description,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$displayName,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [Alias('FirstName')]
    [String]$givenName,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$iPPhone,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [Alias('WindowsEmailAddress')]
    [Alias('Email')]
    [String]$mail,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$name,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [Alias('Office')]
    [String]$physicalDeliveryOfficeName,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$proxyAddress,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$SAMAccountName,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$SipAddress,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [Alias('LastName')]
    [String]$sn,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$Enabled,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$Disabled,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$LyncEnabled,

    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [Switch]$LyncDisabled,
    
    [Parameter(ParameterSetName = 'ByMergedFilter')]
    [ValidateNotNullOrEmpty()]
    [String]$LdapFilter,
    
    [ValidatePattern('^(?:(?:OU|CN|DC)=[^=]+,)*DC=[^=]+$')]
    [ValidateNotNullOrEmpty()]
    [String]$SearchRoot,
    
    [DirectoryServices.SearchScope]$SearchScope = [DirectoryServices.SearchScope]::Subtree,
  
    [String[]]$Properties,
    
    [ValidateRange(0, 1000)]
    [Int32]$SizeLimit = 100,

    [Switch]$UseGC,

    [ValidateNotNullOrEmpty()]
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  begin {
    if (($Enabled -and $Disabled) -or ($LyncEnabled -and $LyncDisabled) -or $CreatedOn -and ($CreatedBefore -or $CreatedAfter)) {
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
    $psboundparameters.Keys |
      Where-Object { $_ -in (Get-KSCommandParameters Get-KSADObject -ParameterNamesOnly) } |
      ForEach-Object {
        $Params.Add($_, $psboundparameters[$_])
      }

    switch ($pscmdlet.ParameterSetName) {
      'ByIdentity' {
        $LdapFilter = ConvertFromKSADIdentity $Identity
        break
      }
      'ByMergedFilter' {
        $LdapFilterParts = "(objectClass=user)", "(objectCategory=person)"
        
        if ($LdapFilter)                 { $LdapFilterParts += $LdapFilter }
        if ($ANR)                        { $LdapFilterParts += "(anr=$ANR)" }
        if ($CreatedAfter)               { $LdapFilterParts += "(whenCreated>=$((Get-Date $CreatedAfter).ToString('yyyyMMddHHmmss.0Z')))" }
        if ($CreatedBefore)              { $LdapFilterParts += "(whenCreated<=$((Get-Date $CreatedBefore).ToString('yyyyMMddHHmmss.0Z')))" }
        if ($CreatedOn)                  { $CreatedBefore = (Get-Date $CreatedOn).Date.AddDays(1).AddSeconds(-1); $CreatedAfter = (Get-Date $CreatedOn).Date; }
        if ($department)                 { $LdapFilterParts += "(department=$department)" }
        if ($description)                { $LdapFilterParts += "(description=$description)" }
        if ($displayName)                { $LdapFilterParts += "(displayName=$displayName)" }
        if ($givenName)                  { $LdapFilterParts += "(givenName=$givenName)" }
        if ($iPPhone)                    { $LdapFilterParts += "(ipPhone=$iPPhone)" }
        if ($mail)                       { $LdapFilterParts += "(mail=$mail)" }
        if ($name)                       { $LdapFilterParts += "(name=$name)" }
        if ($physicalDeliveryOfficeName) { $LdapFilterParts += "(physicalDeliveryOfficeName=$physicalDeliveryOfficeName)" }
        if ($proxyAddress)               { if ($ProxyAddress -notmatch '^(?:[^:]+:)|\*') { $ProxyAddress = "*$proxyAddress" }; $LdapFilterParts += "(proxyAddresses=$proxyAddress)" }
        if ($sAMAccountName)             { $LdapFilterParts += "(sAMAccountName=$sAMAccountName)" }
        if ($SipAddress)                 { if ($SipAddress -notmatch '^sip:') { $SipAddress = "sip:$SipAddress" }; $LdapFilterParts += "(proxyAddresses=$SipAddress)" }
        if ($sn)                         { $LdapFilterParts += "(sn=$sn)" }
        if ($Enabled)                    { $LdapFilterParts += "(!userAccountControl:1.2.840.113556.1.4.803:=2)" }
        if ($Disabled)                   { $LdapFilterParts += "(userAccountControl:1.2.840.113556.1.4.803:=2)" }
        if ($LyncEnabled)                { $LdapFilterParts += "(msRTCSIP-UserEnabled=TRUE)" }
        if ($LyncDisabled)               { $LdapFilterParts += "(!msRTCSIP-UserEnabled=TRUE)" }

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
        $_.PSObject.TypeNames.Add("KScript.AD.User")
        
        $_
      }
    }
  }
}