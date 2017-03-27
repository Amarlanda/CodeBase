# BusType: http://msdn.microsoft.com/en-us/library/windows/desktop/hh830493(v=vs.85).aspx
New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.MSFTDisk.BusType" -Type "Byte" -Members @{
  Unknown           = 0     # The SAN policy is unknown.
  SCSI              = 1
  ATAPI             = 2
  ATA               = 3
  IEEE1394          = 4
  SSA               = 5
  FibreChannel      = 6
  USB               = 7
  RAID              = 8
  iSCSI             = 9
  SAS               = 10
  SATA              = 11
  SD                = 12    # Secure Digital
  MMC               = 13    # Multimedia Card
  Virtual           = 14
  FileBackedVirtual = 15
  StorageSpaces     = 16
  NVMe              = 17
}