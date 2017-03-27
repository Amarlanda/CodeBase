# OfflineReason: http://msdn.microsoft.com/en-us/library/windows/desktop/hh830493(v=vs.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.MSFTDisk.OfflineReason" -Type "Byte" -Members @{
  Policy                    = 1
  RedundantPath             = 2
  Snapshot                  = 3
  Collision                 = 4
  ResoourceExhaustion       = 5
  CriticalWriteFailures     = 6
  DataIntegrityScanRequired = 7
}