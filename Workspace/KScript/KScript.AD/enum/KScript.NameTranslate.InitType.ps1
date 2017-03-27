New-KSEnum -ModuleBuilder $Script:ADModuleBuilder -Name "KScript.NameTranslate.InitType" -Type "Byte" -Members @{
  Domain = 1    # Initializes a NameTranslate object by setting the domain that the object binds to.
  Server = 2    # Initializes a NameTranslate object by setting the server that the object binds to.
  GC     = 3    # Initializes a NameTranslate object by locating the global catalog that the object binds to.
}