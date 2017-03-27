function Import-KSLyncSession {
  # .SYNOPSIS
  #   Import a PSSession based on a LyncManagementURI.
  # .DESCRIPTION
  #   Import-KSLyncSession imports a Lync session into the users global scope.
  # .PARAMETER LyncManagementURI
  #   Import-KSLyncSession uses the LyncManagementURI globally advertised using Get-KSSetting. An alternate LyncManagementURI may be specified if required.
  # .INPUTS
  #   System.URI
  # .EXAMPLE
  #   Import-KSLyncSession
  #
  #   The KSSetting (Get-KSSetting) LyncManagementURI will be used.
  # .EXAMPLE
  #   Import-KSLyncSession -LyncManagementURI "https://lyncserver/ocspowershell"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/09/2014 - Chris Dent - Bugfix: Bad error handling.
  #     13/08/2014 - Chris Dent - Modified function to import session once only (per session).
  #     17/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [Alias('ConnectionURI')]
    [URI]$LyncManagementURI = (Get-KSSetting LyncManagementURI -ExpandValue)
  )
  
  if (-not $LyncManagementURI) {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      (New-Object ArgumentException "LyncManagementURI setting missing or unavailable."),
      "ArgumentException",
      [Management.Automation.ErrorCategory]::InvalidArgument,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }

  if (-not $Script:LyncManagementModule) {
    Write-KSLog "Importing Lync management session."
    
    $PSSession = New-PSSession -ConnectionUri $LyncManagementURI -Authentication Negotiate -ErrorVariable SessionError -ErrorAction SilentlyContinue
    if ($?) {
      New-Variable LyncManagementModule -Scope Script -Value (Import-PSSession $PSSession -AllowClobber)
    } else {
      $SessionError | ForEach-Object {
        Write-Error $SessionError.Exception.Message.Trim()
      }
    }
  }
}