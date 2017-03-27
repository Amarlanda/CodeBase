New-KSEnum -ModuleBuilder $Script:WmiModuleBuilder -Name "KScript.Wmi.SoftwareLicensingProduct.LicenseStatus" -Type "Int32" -Members @{
  Unlicensed      = 0
  Licensed        = 1
  OOBGrace        = 2
  OOTGrace        = 3
  NonGenuiceGrace = 4
  Notification    = 5
  ExtendedGrace   = 6
}