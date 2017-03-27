New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.Security.AccessRight" -Type "Int32" -SetFlagsAttribute -Members @{
  Enable          = 1
  Execute         = 2
  FullWriteRep    = 4
  PartialWriteRep = 8
  WriteProvider   = 16
  RemoteAccess    = 32
  Subscribe       = 64
  Publish         = 128
  ReadControl     = 131072
  WriteDAC        = 262144
}