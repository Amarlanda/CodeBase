# UniqueIdFormat: http://msdn.microsoft.com/en-us/library/windows/desktop/hh830493(v=vs.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.MSFTDisk.UniqueIdFormat" -Type "Byte" -Members @{
  VendorSpecific = 0
  VendorId       = 1
  EU164          = 2
  FCPHName       = 3
  SCSINameString = 8
}