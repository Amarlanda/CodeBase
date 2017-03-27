# SAN Policy enumeration: http://msdn.microsoft.com/en-us/library/bb525577(VS.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.SANPolicy" -Type "Byte" -Members @{
  Unknown       = 0    # The SAN policy is unknown.
  Online        = 1    # All newly discovered disks are brought online and made read-write.
  OfflineShared = 2    # All newly discovered disks that do not reside on a shared bus are brought online and made read-write.
  Offline       = 3    # All newly discovered disks remain offline and read-only.
}