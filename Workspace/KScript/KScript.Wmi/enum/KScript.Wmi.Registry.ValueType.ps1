New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.Registry.ValueType" -Type "UInt32" -Members @{
  String         = 1     # REG_SZ
  ExpandedString = 2     # REG_EXPAND_SZ
  Binary         = 3     # REG_BINARY
  "32Bit"        = 4     # REG_DWORD
  MultiString    = 7     # REG_MULTI_SZ
  "64Bit"        = 11    # REG_QWORD
}