function Get-KSESXLicense {
  # .SYNOPSIS
  #   Get licences from an ESX host.
  # .DESCRIPTION
  # .PARAMETER VMHost
  # .PARAMETER Credential
  # .NOTES
  #   Author: Amar Landa & Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     15/01/2015 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
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
    $GetParams = @{}
    if ($psboundparameters.ContainsKey("VMHost")) {
      $GetParams.Add("Name", $VMHost)
    }
    Get-VMHost @GetParams | ForEach-Object {
      $VMHost = $_.Name
      $LicenseAssignmentManager.QueryAssignedLicenses($_.ExtensionData.MoRef.Value).AssignedLicense |
        Select-Object `
          @{n='VMHost';e={ $VMHost }},
          LicenseKey,
          EditionKey,
          Name,
          Total,
          Used,
          @{n='ExpirationDate';e={ $_.Properties['expirationDate'] }}
    }
  }
}