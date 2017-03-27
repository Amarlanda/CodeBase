New-KSEnum -ModuleBuilder $DnsResolverModuleBuilder -Name "KScript.DnsResolver.OpCode" -Type "UInt16" -Members @{
  Query  = 0;    # [RFC1035]
  IQuery = 1;    # [RFC3425]
  Status = 2;    # [RFC1035]
  Notify = 4;    # [RFC1996]
  Update = 5;    # [RFC2136]
}

