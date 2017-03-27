New-KSEnum -ModuleBuilder $DnsResolverModuleBuilder -Name "KScript.DnsResolver.SSHAlgorithm" -Type "Byte" -Members @{
  RSA = 1;    # [RFC4255]
  DSS = 2;    # [RFC4255]
}

