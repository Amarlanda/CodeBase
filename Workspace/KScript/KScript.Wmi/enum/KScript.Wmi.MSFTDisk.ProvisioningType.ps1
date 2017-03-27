# ProvisioningType: http://msdn.microsoft.com/en-us/library/windows/desktop/hh830493(v=vs.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.MSFTDisk.ProvisioningType" -Type "Byte" -Members @{
  Unknown = 0
  Thin    = 1
  Fixed   = 2
}