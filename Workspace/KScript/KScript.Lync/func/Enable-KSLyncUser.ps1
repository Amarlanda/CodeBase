function Enable-KSLyncUser {
  # .SYNOPSIS
  #   Lync enable users created within the specified time frame.
  # .DESCRIPTION
  #   Enable-KSLyncUser searches AD using Get-CsADUser for accounts created within the period defined by CreatedWithin.
  #
  #   Each user is enabled using the users e-mail address as the SIP address.
  #
  #   Users whose primary SMTP address is not @kpmg.co.uk will be reported but will not be enabled.
  #
  #   Post-enable operations are loaded from XML then tested and executed.
  # .PARAMETER ConnectionURI
  #   A PS session is created based on the specified ConnectionURI then imported into the current PS session. By default, https://ukdcaldw001.uk.kworld.kpmg.com/ocspowershell is used as the ConnectionURI.
  # .PARAMETER CreatedWithin
  #   By default Enable-KSLyncUser looks for accounts created within 5 days of the beginning of the current day (today at 00:00:00 minus 5 days). An alternative time-frame may be specified using this parameter.
  # .PARAMETER PostEnableCommandsFile
  #   Commands described by the specified XML file will be executed after accounts have been enabled.
  # .PARAMETER SearchRoot
  #   The starting point for the Active Directory search. SearchRoot is mandatory as Get-CsAdUser performs a forest-wide search without this.
  # .INPUTS
  #   System.TimeSpan
  #   System.String
  # .OUTPUTS
  #   KScript.Lync.UserReportEntry
  # .EXAMPLE
  #   Enable-KSLyncUser
  #
  #   Enable all users under the default SearchRoot created within 5 days of today's date.
  # .EXAMPLE
  #   Enable-KSLyncUser -CreatedWithin (New-TimeSpan -Days 10)
  #
  #   Enable all users under the default SearchRoot created within 10 days of today's date.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/09/2014 - Chris Dent - BugFix: Fixed display of SIPAddress where none are available to use.
  #     13/08/2014 - Chris Dent - Updated registrar pool split.
  #     24/07/2014 - Chris Dent - Added parameter validation for SearchRoot (passed as OU to Get-CsAdUser).
  #     23/07/2014 - Chris Dent - Added text logging.
  #     22/07/2014 - Chris Dent - Moved session import to Import-KSLyncSession.
  #     18/07/2014 - Chris Dent - Split PostEnableCommands into a second pass loop.
  #     25/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$SearchRoot = "ou=Function,dc=uk,dc=kworld,dc=kpmg,dc=com",

    [TimeSpan]$CreatedWithin = (New-TimeSpan -Days 5),
    
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$PostEnableCommandsFile = (Resolve-Path "$psscriptroot\..\var\post-enable-commands.xml")
  )
  
  Write-KSLog "Started $($myinvocation.InvocationName)"
  
  if ($psboundparameters.ContainsKey("WhatIf")) {
    Write-KSLog "WhatIf is set, no changes will be made."
  }
  
  if ($pscmdlet.ShouldProcess("Importing Lync management session.")) {
    Import-KSLyncSession
    if (-not $?) {
      break
    }
  } else {
    if (-not (Get-Command Get-CsAdUser)) {
      Write-KSLog "Get-CsAdUser command not found; Lync module not loaded." -LogLevel Warning
      break
    }
  }
  
  # Import commands described by PostEnableCommands.
  
  if ($PostEnableCommandsFile) {
    $XPathNavigator = New-KSXPathNavigator -FileName $PostEnableCommandsFile
    
    $PostEnableCommands = $XPathNavigator.Select("/post-enable-commands/post-enable-command") | ForEach-Object {
      # Construct an object which consists of:
      # Match, Property and Commands (full command string)
      $Commands = $_.Select("./commands/command") | ForEach-Object {
        $Command = $_.Select('./name').TypedValue
        
        if (-not (Get-Command $Command -Module Lync)) {
          Write-KSLog "Invalid command specified ($Command). Ignoring command." -LogLevel Warning
        } else {
          $Parameters = $_.Select('./parameters/parameter') | ForEach-Object {
            $ParameterName = $_.Select('./name').TypedValue
            if (-not (Get-Command $Command -Module Lync).Parameters[$ParameterName]) {
              Write-KSLog "Invalid parameter specified ($Command : $ParameterName)" -LogLevel Warning
              # Prevent this command being used.
              $Command = $null
            } else {
              $ParameterValue = $_.Select('./value').TypedValue
              # Convert boolean values
              if ($ParameterValue -match '^(true|false)$') {
                $ParameterValue = "`$$((Get-Variable $ParameterValue).Value)"
              } else {
                $ParameterValue = """$ParameterValue"""
              }
              
              "-$ParameterName $ParameterValue"
            }
          }
          
          # Assemble the command. Note: The Identity argument variables are hard-coded here.
          if ($Command) { "$Command -Identity `$CsUser.Identity $Parameters -ErrorAction Stop" }
        }
      }
      
      $MatchProperty = $_.Select('match-property').TypedValue
      $_.Select('./match-patterns/match-pattern') | ForEach-Object {
        New-Object PSObject -Property ([Ordered]@{
          Match    = $_.TypedValue.Trim()
          Property = $MatchProperty
          Commands = $Commands
        })
      } | Where-Object Commands
    }
  }
  
  # Generate an LDAP filter to use for this search
  $WhenCreated = ((Get-Date).Date - $CreatedWithin).ToString('yyyyMMddHHmmss.0Z')
  $LdapFilter = "(&(objectClass=user)(objectCategory=person)(!msRTCSIP-UserEnabled=TRUE)(whenCreated>=$WhenCreated)(!userAccountControl:1.2.840.113556.1.4.803:=2)(mail=*))"
  
  Write-KSLog "Starting AD query"
  Write-KSLog "  Using LdapFilter $LdapFilter"
  Write-KSLog "  Using $SearchRoot"
  
  $UserReportEntries = Get-CsAdUser -LDAPFilter $LdapFilter -OU $SearchRoot | ForEach-Object {
    Write-KSLog "User: $($_.SamAccountName)"
  
    # Ensure this is not carried from the last user.
    $RegistrarPool = $null
    
    $CsUser = $_

    $EnableCsUserParams = @{}
    if ($_.WindowsEmailAddress -notmatch '@kpmg\.co\.uk$') {
      $EnableType = "ManualSIPAddress"
      
      # Attempt to get an alternate SMTP address
      $SIPAddress = ($CsUser.ProxyAddresses | Where-Object { $_ -match 'smtp:[^@]+@kpmg\.co\.uk' } | Select-Object -First 1) -replace 'smtp:', 'sip:'
      if ($SIPAddress) {
        $EnableCsUserParams.Add("SIPAddress", $SIPAddress)
        $Status = "OK - Secondary SMTP address used"
      } else {
        $Status = "Skipped - No available SMTP addresses in @kpmg.co.uk"
        $SipAddress = ""
      }
    } else {
      $EnableType = "AutomaticSIPAddress"; $Status = "OK"
      $SipAddress = "sip:$($_.WindowsEmailAddress)"
  
      $EnableCsUserParams.Add("SipAddressType", "EmailAddress")
    }
    
    if ($Status -match '^OK') {
      $RegistrarPool = switch -regex ($CsUser.LastName) {
        '^[A-L]' { 'UKDCALNC001.uk.kworld.kpmg.com'; break }
        '^[M-Z]' { 'UKDCBLNC001.uk.kworld.kpmg.com'; break }
        default  { 'UKDCALNC001.uk.kworld.kpmg.com' }
      }

      try {
        Write-KSLog "  Enabling Lync user $($CsUser.Identity)"
        if ($pscmdlet.ShouldProcess("Enabling Lync user $($CsUser.Identity)")) {
          $Error.Clear()
          Enable-CsUser -Identity $CsUser.Identity -RegistrarPool $RegistrarPool @EnableCsUserParams -ErrorAction Stop
          if ($Error) {
            Write-KSLog "  Enable-CsUser: $($Error[0].Exception.Message)" -LogLevel Error
            $Status = "Failed - Enable-CsUser: $($Error[0].Exception.Message)"
          }
        }
      } catch {
        Write-KSLog "  Enable-CsUser: $($_.Exception.Message)" -LogLevel Error
        $Status = "Failed - Enable-CsUser: $($_.Exception.Message)"
      }
    }
    
    # Find any post-enable 
    $UserCommands = $PostEnableCommands |
      Where-Object { $CsUser.($_.Property) -match $_.Match } |
      Select-Object -ExpandProperty Commands
    
    $UserReportEntry = New-Object PSObject -Property ([Ordered]@{
      UserName                = $_.SamAccountName
      DN                      = $_.DistinguishedName
      EnableType              = $EnableType
      DisplayName             = $_.DisplayName
      WhenCreated             = $_.WhenCreated
      RegistrarPool           = $RegistrarPool
      SipAddress              = $SipAddress
      PostEnableCommand       = ($UserCommands -join "`n")
      PostEnableCommandStatus = "N/A"
      Result                  = $Status
    })
    $UserReportEntry.PSObject.TypeNames.Add("KScript.Lync.UserReportEntry")
    
    Write-KSLog "  EnableType:    $EnableType"
    Write-KSLog "  RegistrarPool: $RegistrarPool"
    Write-KSLog "  SIPAddress:    $SIPAddress"
    Write-KSLog "  Result:        $Status"
    
    # Leave this in the output pipeline
    $UserReportEntry
  }

  # Execute post-enable commamds

  $FirstPass = $true
  $UserReportEntries | ForEach-Object {
    if ($_.PostEnableCommand -and $_.Result -eq 'OK') {
      if ($FirstPass) {
        Write-KSLog "Sleeping for 1 minute to allow changes to propagate"
        Start-Sleep -Seconds 60
        $FirstPass = $false
      }

      Write-KSLog "Post-enable commands: User: $($_.UserName)"

      $PostEnableCommandStatus = @(); $DN = $_.DN
      $_.PostEnableCommand -split "`n" | ForEach-Object {
        $Command = $_
        Write-KSLog "  Command: $Command"
        try {
          if ($pscmdlet.ShouldProcess("Executing $Command for $DN")) {
            $CsUser = Get-CsUser -Identity $DN -ErrorAction Stop
            if ($CsUser) {
              $Error.Clear()
              Invoke-Expression $Command
              if ($Error) {
                Write-KSLog "  Post-enable command failed: $Command :: $($Error[0].Exception.Message)" -LogLevel Error
                $Status = "Failed - Post-enable command failed: $Command :: $($Error[0].Exception.Message)"
              }
            }
          }
        } catch {
          Write-KSLog "  Post-enable command failed: $Command :: $($_.Exception.Message)" -LogLevel Error
          $PostEnableCommandStatus += "Failed - Post-enable command failed: $Command :: $($_.Exception.Message)"
        }
      }
      if ($PostEnableCommandStatus) {
        $_.PostEnableCommandStatus = "$PostEnableCommandStatus"
      } else {
        $_.PostEnableCommandStatus = "OK"
      }
    }

    # Leave the final report entry in the output pipeline (regardless of status)
    $_
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)"
}

