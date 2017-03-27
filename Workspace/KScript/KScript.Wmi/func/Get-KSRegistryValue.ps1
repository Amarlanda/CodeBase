function Get-KSRegistryValue {
  # .SYNOPSIS
  #   Get values from the registry using the StdRegProv class and the CIM CmdLets.
  # .DESCRIPTION
  #   Get-KSRegistryValue is a wrapper to simplify use of the StdRegProv class using New-CimSession, Get-CimClass and Invoke-CimMethod.
  # .PARAMETER ComputerName
  #   The name of the computer to query.
  # .PARAMETER Credential
  #   Credentials for the connection.
  # .PARAMETER Hive
  #   The registry hive to query. By default HKLM (Local Machine) is used. Alternatives are HKCR (Classes Root), HKCU (Current User), HKU (Users) and HKCC (Current Config).
  # .PARAMETER Key
  #   The name of the registry key to export (relative to the hive).
  # .PARAMETER Name
  #   The name of a value to retrieve. By default, all values from the key are returned.
  # .PARAMETER Recurse
  #   Recurse through child keys.
  # .EXAMPLE
  #   Get-KSRegistryValue -Key SYSTEM\CurrentControlSet\Control
  # .EXAMPLE
  #   Get-KSRegistryValue -Key "Control Panel\Desktop" -Hive HKCU
  # .EXAMPLE
  #   Get-KSRegistryValue -Key System\CurrentControlSet\Control\ComputerName\ActiveComputerName -Name ComputerName -ComputerName SomeComputer
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     06/01/2015 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'SeparateValues')]
  param(
    [Parameter(Mandatory = $true, ParameterSetName = 'SeparateValues')]
    [ValidateNotNullOrEmpty()]
    [String]$Key,

    [Parameter(ParameterSetName = 'SeparateValues')]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [Parameter(ParameterSetName = 'SeparateValues')]
    [ValidateNotNullOrEmpty()]
    [KScript.Wmi.Registry.Hive]$Hive = [KScript.Wmi.Registry.Hive]::HKLM,
    
    [Switch]$Recurse,

    [String]$ComputerName = $env:ComputerName,
    
    [PSCredential]$Credential
  )
  
  begin {
    $CimSessionOptions = New-CimSessionOption -Protocol Dcom -Culture (Get-Culture) -UICulture (Get-Culture)
  }

  process {
    $NewParams = @{
      ComputerName  = $ComputerName;
      SessionOption = $CimSessionOptions;
    }
    if ($psboundparameters.ContainsKey("Credential")) {
      $NewParams.Add("Credential", $Credential)
    }
    $CimSession = New-CimSession @NewParams
    if ($?) {
      $CimClass = Get-CimClass StdRegProv -Namespace root/default -CimSession $CimSession -OperationTimeoutSec 30

      $EnumArguments = @{
        hDefKey     = $Hive;
        sSubKeyname = $Key;
      }
      $ValuesAndTypes = Invoke-CimMethod -MethodName EnumValues -CimClass $CimClass -Arguments $EnumArguments -CimSession $CimSession -OperationTimeoutSec 30
   
      $Values = New-Object PSObject -Property ([Ordered]@{
        Key = $Key
      })
      
      if ($ValuesAndTypes.ReturnValue -eq 0) {
        $Count = $ValuesAndTypes.sNames.Count
        for ($i = 0; $i -lt $Count; $i++) {
          if (-not $psboundparameters.ContainsKey("Name") -or $Name -eq $ValuesAndTypes.sNames[$i]) {
            $ValueName = $ValuesAndTypes.sNames[$i]
            $ValueType = [KScript.Wmi.Registry.ValueType]$ValuesAndTypes.Types[$i]
          
            $GetArguments = @{
              hDefKey     = $Hive;
              sSubKeyname = $Key;
              sValueName  = $ValuesAndTypes.sNames[$i]
            }
            
            $MethodName = switch ($ValueType) {
              ([KScript.Wmi.Registry.ValueType]::String)         { "GetStringValue" }
              ([KScript.Wmi.Registry.ValueType]::ExpandedString) { "GetExpandedStringValue" }
              ([KScript.Wmi.Registry.ValueType]::Binary)         { "GetBinaryValue" }
              ([KScript.Wmi.Registry.ValueType]::"32Bit")        { "GetDWORDValue" }
              ([KScript.Wmi.Registry.ValueType]::MultiString)    { "GetMultiStringValue" }
              ([KScript.Wmi.Registry.ValueType]::"64Bit")        { "GetQWORDValue" }
            }
            $RawValue = Invoke-CimMethod -MethodName $MethodName -CimClass $CimClass -Arguments $GetArguments -CimSession $CimSession -OperationTimeoutSec 30
            
            if ($RawValue.ReturnValue -eq 0) {
              $Value = switch ($ValueType) {
                ([KScript.Wmi.Registry.ValueType]::String)         { [String]$RawValue.sValue }
                ([KScript.Wmi.Registry.ValueType]::ExpandedString) { [String]$RawValue.sValue }
                ([KScript.Wmi.Registry.ValueType]::Binary)         { [Byte[]]$RawValue.uValue }
                ([KScript.Wmi.Registry.ValueType]::"32Bit")        { [UInt32]$RawValue.uValue }
                ([KScript.Wmi.Registry.ValueType]::MultiString)    { [String[]]$RawValue.sValue }
                ([KScript.Wmi.Registry.ValueType]::"64Bit")        { [UInt64]$RawValue.uValue }
              }

              # Any value assigned to "Default" will be blank. Create a name for this value.
              if ($ValueName -eq "") {
                $ValueName = "(Default)"
              }
              
              $Values | Add-Member $ValueName -MemberType NoteProperty -Value $Value
            }
          }
        }
      }
      $Values
      
      if ($Recurse) {
        $Keys = Invoke-CimMethod -MethodName EnumKey -CimClass $CimClass -Arguments $EnumArguments -CimSession $CimSession -OperationTimeoutSec 30
        if ($Keys.ReturnValue -eq 0 -and $Keys.sNames) {
          $Keys.sNames | ForEach-Object {
            $RecurseParams = $psboundparameters
            $RecurseParams['Key'] = "$Key\$_"
            
            Get-KSRegistryValue @RecurseParams
          }
        }
      }
    }
  }
}