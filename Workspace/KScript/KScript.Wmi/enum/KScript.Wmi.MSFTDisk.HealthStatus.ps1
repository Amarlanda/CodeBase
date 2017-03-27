# HealthStatus: http://msdn.microsoft.com/en-us/library/windows/desktop/hh830493(v=vs.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.MSFTDisk.HealthStatus" -Type "Byte" -Members @{
  Unknown = 0
  Healthy = 1
  Failing = 4
  Failed  = 8
}