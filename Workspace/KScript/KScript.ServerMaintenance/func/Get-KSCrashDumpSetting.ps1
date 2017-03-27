function Get-KSCrashDumpSetting {
  [CmdLetBinding()]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$ComputerName = $env:ComputerName
  )
  
  $WmiResponse = Invoke-WmiMethod GetDWordValue -Class StdRegProv -Namespace root/Default -ComputerName $ComputerName -ArgumentList `
    [KScript.Wmi.Registry.Hive]::HKLM,
    "System\CurrentControlSet\Control\CrashControl",
    "CrashDumpEnabled"

  [KScript.Server.CrashDump]$WmiResponse['uValue']
}