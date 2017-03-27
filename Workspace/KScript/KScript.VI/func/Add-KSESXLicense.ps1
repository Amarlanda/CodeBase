function Add-KSESXLicense {
  # .SYNOPSIS
  #   Add licences to an ESX host.
  # .DESCRIPTION
  # .PARAMETER VMHost
  # .PARAMETER Credential
  # .PARAMETER LicenseKey
  # .PARAMETER LicenseName
  # .NOTES
  #   Author: Amar Landa & Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/01/2015 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$LicenseKey,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$LicenseName,
  
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$VMHost
  )

  begin {
    if ($Global:DefaultVIServers) {
      $LicenseAssignmentManager = Get-View LicenseAssignmentManager-LicenseAssignmentManager
    } else {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object InvalidOperationException "Add-KSESXLicense: Must be connected to a vCenter server or an ESX host to perform this operation."),
        "InvalidOperation",
        [Management.Automation.ErrorCategory]::OperationStopped,
        $VMHost)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)    
    }
  }
  
  process {
    $VMHostObject = Get-VMHost $VMHost
    if ($VMHostObject) {
      $LicenseAssignmentManager.UpdateAssignedLicense(
        $VMHostObject.ExtensionData.MoRef.Value,
        $LicenseKey,
        $LicenseName
      )
    } else {
      Write-Error "Add-KSESXLicense: VMHost ($VMHost) not found on connected VIServer."
    }
  }
}