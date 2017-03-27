function NewKSADDirectoryEntry {
  # .SYNOPSIS
  #   Creates an instance of a new System.DirectoryServices.DirectoryEntry class based on the specified parameters.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   Instantiates the System.DirectoryServices.DirectoryEntry class.
  # .PARAMETER ComputerName
  #   Bind using a specific computer name.
  # .PARAMETER Credential
  #   Credentials for the operation.
  # .PARAMETER DirectoryPath
  #   A DirectoryPath in the form "LDAP://<DN>" or "WinNT://<object>".
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   KScript.AD.DirectoryEntry
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     03/12/2014 - Chris Dent - Added System.DirectoryServices.AccountManagement.PrincipalContext as a member of the DirectoryEntry object.
  #     03/12/2014 - Chris Dent - BugFix: The first argument in the constructor must be supplied as $null if not explicitly declared when credentials are used.
  #     17/11/2014 - Chris Dent - BugFix: Default Exception catch.
  #     13/11/2014 - Chris Dent - BugFix: Credential passing for directory entries.
  #     22/09/2014 - Chris Dent - BugFix: LDAP path construction when a search root is supplied.
  #     23/07/2014 - Chris Dent - Changed parameter LdapPath to DirectoryPath.
  #     03/06/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [String]$DirectoryPath,
    
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )
  
  # Build System.DirectoryServices.DirectoryEntry
  
  $ConstructorArgs = @()
  # Null LDAP paths are permissible, the defaultNamingContext is used. If a ComputerName is specified the path must be defined.
  if ($psboundparameters.ContainsKey("DirectoryPath")) {
    $ConstructorArgs += $DirectoryPath
  } elseif (-not $psboundparameters.ContainsKey("DirectoryPath") -and $psboundparameters.ContainsKey("ComputerName")) {
    # If an LDAP path is not specified, but a ComputerName is, create a default value which can be changed in the next step.
    $ConstructorArgs += "LDAP://"
  }
  # Modify the LDAP path to include the specified ComputerName (if ComputerName is not already included).
  if ($psboundparameters.ContainsKey("ComputerName") -and $ConstructorArgs[0] -notmatch "//$ComputerName") {
    if ($ConstructorArgs[0] -match '//.+') {
      $ConstructorArgs[0] = $ConstructorArgs[0] -replace '//(.+)', ('//' + $ComputerName + '/$1')
    } else {
      $ConstructorArgs[0] = $ConstructorArgs[0] -replace '//', "//$ComputerName"
    }
  }
  if ($psboundparameters.ContainsKey("Credential")) {
    # If credentials are supplied and a DirectoryPath is not pass null as the first argument for the constructor.
    if ($ConstructorArgs.Count -lt 1) {
      $ConstructorArgs += $null
    }

    $ConstructorArgs += $Credential.Username
    $ConstructorArgs += $Credential.GetNetworkCredential().Password
  }
  
  try {
    $DirectoryEntry = New-Object DirectoryServices.DirectoryEntry($ConstructorArgs)
  } catch [UnauthorizedAccessException] {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object UnauthorizedAccessException "Access is denied"),
      "UnauthorizedAccessException",
      [Management.Automation.ErrorCategory]::PermissionDenied,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  } catch {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      $_.Exception,
      "ADSI connection failed.",
      [Management.Automation.ErrorCategory]::OperationStopped,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }

  # Build System.DirectorySerivces.AccountManagement.PrincipalContext

  if ($DirectoryPath -notmatch '^WinNT://') {
    $ConstructorArgs = @([DirectoryServices.AccountManagement.ContextType]::Domain)
    if ($psboundparameters.ContainsKey("ComputerName")) {
      $ConstructorArgs += $ComputerName
    } else {
      if ($psboundparameters.ContainsKey("DirectoryPath") -or $psboundparameters.ContainsKey("Credential")) {
        # If the ComputerName is not supplied default to using the UserDnsDomain environment variable.
        $ConstructorArgs += $env:UserDnsDomain
      }
    }
    if ($psboundparameters.ContainsKey("DirectoryPath") -and $DirectoryPath -match '^LDAP:') {
      $ConstructorArgs += $DirectoryPath -replace '^LDAP://([^/]+/)?'
    }
    if ($psboundparameters.ContainsKey("Credential")) {
      $ConstructorArgs += $Credential.Username
      $ConstructorArgs += $Credential.GetNetworkCredential().Password
    }
    if ($psboundparameters.ContainsKey("DirectoryPath") -and $psboundparameters.ContainsKey("ComputerName") -and -not $psboundparameters.ContainsKey("Credential")) {
      $ConstructorArgs += [DirectoryServices.AccountManagement.ContextOptions]::Negotiate
    }
    
    $PrincipalContext = New-Object DirectoryServices.AccountManagement.PrincipalContext($ConstructorArgs)

    # Add the PrincipalContext as a property member of the DirectoryEntry object
    if ($PrincipalContext) {
      $DirectoryEntry.PSBase | Add-Member PrincipalContext -MemberType NoteProperty -Value $PrincipalContext
    }
  }
  
  $DirectoryEntry.PSObject.TypeNames.Add("KScript.AD.DirectoryEntry")
  
  return $DirectoryEntry
}