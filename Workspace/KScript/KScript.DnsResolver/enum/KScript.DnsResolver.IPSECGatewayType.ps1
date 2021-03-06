New-KSEnum -ModuleBuilder $DnsResolverModuleBuilder -Name "KScript.DnsResolver.IPSECGatewayType" -Type "Byte" -Members @{
  NoGateway  = 0;    # No gateway is present                    [RFC4025]
  IPv4       = 1;    # A 4-byte IPv4 address is present         [RFC4025]
  IPv6       = 2;    # A 16-byte IPv6 address is present        [RFC4025]
  DomainName = 3;    # A wire-encoded domain name is present    [RFC4025]
}

