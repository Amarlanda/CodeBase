New-KSEnum -ModuleBuilder $Script:ServerModuleBuilder -Name "KScript.Server.CrashDump" -Type "Int32" -Members @{
  Disabled         = 0
  CrashDump        = 1
  KernelMemoryDump = 2
  SmallMemoryDump  = 3
}