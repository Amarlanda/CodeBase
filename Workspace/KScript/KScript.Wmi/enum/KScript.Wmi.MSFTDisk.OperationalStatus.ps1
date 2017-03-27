# OperationalStatus: http://msdn.microsoft.com/en-us/library/windows/desktop/hh830493(v=vs.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.MSFTDisk.OperationalStatus" -Type "Byte" -Members @{
  Unknown  = 0
  Online   = 1
  NotReady = 2
  NoMedia  = 3
  Offline  = 4
  Failed   = 5
  Missing  = 6
}