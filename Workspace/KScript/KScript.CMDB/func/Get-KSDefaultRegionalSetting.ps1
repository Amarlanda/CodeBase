function Get-KSDefaultRegionalSetting {
  # .SYNOPSIS
  #   Get the default regional settings.
  # .DESCRIPTION
  #   Get-KSDefaultRegionalSetting attempts to get a number of country-specific regional settings from the specified computer.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER Credential
  #   By default current user is used, alternate credentials may be specified if required.
  # .PARAMETER UUID
  #   A universally unique identifier drawn from Win32_ComputerSystemProduct.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.DefaultRegionalSetting
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     14/11/2014 - Chris Dent - Updated to use KScript.Wmi library.
  #     10/10/2014 - Chris Dent - Finished help text. Added UUID.
  #     14/08/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$ComputerName = (hostname),

    [PSCredential]$Credential
  )
  
  process {
    #$CimSession = New-CimSession @psboundparameters -OperationTimeoutSec 30
    #$CimClass = Get-CimClass StdRegProv -Namespace root\default -CimSession $CimSession

    #$DefaultRegionalSetting = New-Object PSobject ([Ordered]@{
    #  Country               = "HKU:.DEFAULT\Control Panel\International:sCountry"
    #  CountryCode           = "HKU:.DEFAULT\Control Panel\International:iCountry"
    #  DefaultKeyboardLayout = 
    #})
    #
    #Invoke-CimMethod -CimClass $CimClass -MethodName EnumValues -Arguments @{
    #  hDefKey      = [UInt32][KScript.Wmi.Registry.Hive]::HKU
    #  sSubKeyName  = ".DEFAULT\Control Panel\International"
    #}
    #
    #Invoke-CimMethod -CimClass $CimClass -MethodName GetStringValue -CimSession $CimSession -Arguments @{
    #  hDefKey      = [UInt32][KScript.Wmi.Registry.Hive]::HKU
    #  sSubKeyName  = ".DEFAULT\Control Panel\International"
    #}

    try {
      $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey([Microsoft.Win32.RegistryHive]::Users, $ComputerName)
    } catch [Exception] {
      $Message = $_.Exception.Message -replace "`n"
      Write-Error "ComputerName: $ComputerName :: $Message :: LocalMachine"
    }
    
    if ($?) {
      $InternationalSetting = $BaseKey.OpenSubKey(".DEFAULT\Control Panel\International")
      $DefaultKeyboardLayout = $BaseKey.OpenSubKey(".DEFAULT\Keyboard Layout\Preload")
      
      $DefaultRegionalSetting = New-Object PSObject -Property ([Ordered]@{
        Country               = $InternationalSetting.GetValue("sCountry")
        CountryCode           = $InternationalSetting.GetValue("iCountry")
        DefaultKeyboardLayout = [KScript.Wmi.Registry.KeyboardLayout][UInt32]"0x$($DefaultKeyboardLayout.GetValue('1'))"
        Language              = $InternationalSetting.GetValue("sLanguage")
        Locale                = $InternationalSetting.GetValue("LocaleName")
      })
      $DefaultRegionalSetting.PSObject.TypeNames.Add("KScript.CMDB.DefaultRegionalSetting")
      
      $DefaultRegionalSetting
    }
  }
}