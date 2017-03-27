function Set-KSVMOwner {
  # .SYNOPSIS
  #   Set owner information for a specific virtual machine.
  # .DESCRIPTION
  #   Set-KSVMOwner adds information to the following custom properties:
  #
  #     * Service Name
  #     * Service Owner
  #     * Server Role
  #
  # .PARAMETER VMName
  #   The name (as listed in SCVMM) of the virtual machine to change.
  # .PARAMETER ServiceName
  #   The value for the Service Name custom property.
  # .PARAMETER ServiceOwner
  #   The value for the Service Owner custom property.
  # .PARAMETER ServerRole
  #   The value for the Server Role custom property.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Set-KSVMOwner -VM server.domain.example -ServiceName "SomeService" -ServiceOwner "Bob Hope" -ServerRole "SQL"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     31/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$VMName,
    
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$ServiceName,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$ServiceOwner,

    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$ServerRole,
    
    $VIEntity
  )

  process {
    if ($VIEntity) {
      $VM = Get-SCVirtualMachine $VMName
      
      if ($VM) {
        if ($psboundparameters['ServiceName']) {
          Set-KSVMCustomProperty -Property 'Service Name' -Value $ServiceName -VM $VM
        }
        if ($psboundparameters['ServiceOwner']) {
          Set-KSVMCustomProperty -Property 'Service Owner' -Value $ServiceOwner -VM $VM
        }
        if ($psboundparameters['ServerRole']) {
          Set-KSVMCustomProperty -Property 'Server Role' -Value $ServerRole -VM $VM
        }
      }
    }
  }
}