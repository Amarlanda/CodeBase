function Convert-KSADName {
  # .SYNOPSIS
  #   Convert a local or Active Directory account name from one format to another.
  # .DESCRIPTION
  #   Convert a local or Active Directory account name from one format to another using the NameTranslate COMObject.
  #
  #   The following source (and destination) name types are supported:
  #
  #     RFC1779                 Name format as specified in RFC 1779. 
  #                             For example, CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com.
  #     Canonical               Canonical name format. For example, Fabrikam.com/Users/Jeff Smith.
  #     NT4                     Account name format used in Windows. For example, Fabrikam\JeffSmith.
  #     DisplayName             Display name format. For example, Jeff Smith.
  #     DomainSimple            Simple domain name format. For example, JeffSmith@Fabrikam.com.
  #     EnterpriseSimple        Simple enterprise name format. For example, JeffSmith@Fabrikam.com.
  #     GUID                    Global Unique Identifier format. 
  #                             For example, {95ee9fff-3436-11d1-b2b0-d15ae3ac8436}.
  #     Unknown                 Unknown name type. The system will estimate the format. 
  #                             This element is a meaningful option only with the IADsNameTranslate.Set or the 
  #                             IADsNameTranslate.SetEx method, but not with the IADsNameTranslate.Get or 
  #                             IADsNameTranslate.GetEx method.
  #     UserPrincipalName       User principal name format. For example, JeffSmith@Fabrikam.com.
  #     ExtendedCanonical       Extended canonical name format. For example, Fabrikam.com/Users Jeff Smith.
  #     ServicePrincipalName    Service principal name format. For example, www/www.fabrikam.com@fabrikam.com.
  #     SIDorSIDHistoryName     A SID string, as defined in the Security Descriptor Definition Language (SDDL),
  #                             for either the SID of the current object or one from the object SID history.
  #
  # .PARAMETER DestinationNameType
  #   The format of the desired name. By default an RFC1779 style name will be returned (CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com).
  # .PARAMETER Name
  #   The name of the object to convert.
  # .PARAMETER SourceNameType
  #   The format of the existing name. By default an NT4 style name will be expected (domain\user).
  # .INPUTS
  #   KScript.NameTranslate.NameType
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   Convert-KSADName 'domain\user'
  #
  #   Convert the NT4 formatted name to RFC1779, an LDAP distinguished name.
  # .EXAMPLE
  #   Convert-KSADName 'CN=user,OU=somewhere,DC=domain,DC=com' -SourceNameType RFC1779 -DestinationNameType Canonical
  #
  #   Convert the RFC1779 name to a Canonical name.
  # .LINKS
  #   http://msdn.microsoft.com/en-us/library/aa706046(v=vs.85).aspx
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     25/09/2014 - Chris Dent - First release.

  [CmdLetBinding(DefaultParameterSetName = 'NoAuthentication')]
  param(
    [Parameter(Position = 1)]
    [String]$Name,
  
    [KScript.NameTranslate.NameType]$SourceNameType = [KScript.NameTranslate.NameType]::NT4,

    [ValidateScript( { $_ -notmatch 'Unknown' } )]
    [KScript.NameTranslate.NameType]$DestinationNameType = [KScript.NameTranslate.NameType]::RFC1779,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'WithAuthentication')]
    [PSCredential]$Credential,

    [Parameter(Mandatory = $true, ParameterSetName = 'WithAuthentication')]
    [String]$ComputerName
  )
  
  $NameTranslate = New-Object -COMObject NameTranslate
  
  if ($ComputerName -and $Credential) {
    $NetworkCredential = $Credential.GetNetworkCredential()
  
    try {
      [__COMObject].InvokeMember("InitEx", "InvokeMethod", $null, $NameTranslate, @(
        [KScript.NameTranslate.InitType]::Server,
        $ComputerName,
        $NetworkCredential.Username,
        $NetworkCredential.Domain,
        $NetworkCredential.Password
      ))
    } catch [UnauthorizedAccessException] {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object UnauthorizedAccessException "Access is denied"),
        "UnauthorizedAccessException",
        [Management.Automation.ErrorCategory]::PermissionDenied,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    } catch {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        $_.Exception.InnerException,
        $_.Exception.InnerException.Message,
        [Management.Automation.ErrorCategory]::OperationStopped,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
  } else {
    [__COMObject].InvokeMember("Init", "InvokeMethod", $null, $NameTranslate, @([KScript.NameTranslate.InitType]::GC, ""))
  }
  
  try {
    [__COMObject].InvokeMember("Set", "InvokeMethod", $null, $NameTranslate, @($SourceNameType, $Name))
  } catch {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      $_.Exception.InnerException,
      $_.Exception.InnerException.Message,
      [Management.Automation.ErrorCategory]::OperationStopped,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
    
  try {
    [__COMObject].InvokeMember("Get", "InvokeMethod", $null, $NameTranslate, $DestinationNameType)
  } catch {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      $_.Exception.InnerException,
      $_.Exception.InnerException.Message,
      [Management.Automation.ErrorCategory]::OperationStopped,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
}