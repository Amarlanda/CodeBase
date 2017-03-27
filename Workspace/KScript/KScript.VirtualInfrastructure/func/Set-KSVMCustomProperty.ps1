function Set-KSVMCustomProperty {
  # .SYNOPSIS
  #   Set a custom property on a Virtual Machine managed by SCVMM.
  # .DESCRIPTION
  #   Set-KSVMCustomProperty gets, checks and sets a custom property on the specified virtual machine.
  # .PARAMETER Property
  #   The name of the property to set.
  # .PARAMETER Value
  #   The value to set.
  # .PARAMETER VM
  #   The VM object to apply the property to.
  # .INPUTS
  #   Microsoft.SystemCenter.VirtualMachineManager.VM
  #   System.String
  # .EXAMPLE
  #   Get-SCVirtualMachine ukvmssrv143.uk.kworld.kpmg.com | Set-KSVMCustomProperty -Property "SomeProperty" -Value "New Value"
  # .EXAMPLE
  #   Get-KSVM ukvmssrv143.uk.kworld.kpmg.com | Set-KSVMCustomProperty -Property "SomeProperty" -Value "New Value"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     31/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Property,
    
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$Value,
    
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [Alias('VMObject')]
    [Microsoft.SystemCenter.VirtualMachineManager.VM]$VM
  )
  
  $CustomProperty = Get-SCCustomProperty -Name $Property
  if ($CustomProperty) {
    if ($VM.CustomProperty[$Property] -ne $Value -and $Value) {
      Set-SCCustomPropertyValue -InputObject $VM -CustomProperty $CustomProperty -Value $Value
    }
  } else {
    Write-Warning "Set-KSVMCustomProperty: Custom property ($Property) does not exist."
  }
}
