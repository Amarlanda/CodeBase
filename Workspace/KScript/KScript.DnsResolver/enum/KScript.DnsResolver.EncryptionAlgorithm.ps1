New-KSEnum -ModuleBuilder $DnsResolverModuleBuilder -Name "KScript.DnsResolver.EncryptionAlgorithm" -Type "Byte" -Members @{
  RSAMD5               = 1;       # RSA/MD5 (deprecated, see 5)    [RFC3110][RFC4034]
  DH                   = 2;       # Diffie-Hellman                 [RFC2539]
  DSA                  = 3;       # DSA/SHA1                       [RFC3755]
  RSASHA1              = 5;       # RSA/SHA-1                      [RFC3110][RFC4034]
  "DSA-NSEC3-SHA1"     = 6;       # DSA-NSEC3-SHA1                 [RFC5155]
  "RSASHA1-NSEC3-SHA1" = 7;       # RSASHA1-NSEC3-SHA1             [RFC5155]
  RSASHA256            = 8;       # RSA/SHA-256                    [RFC5702]
  RSASHA512            = 10;      # RSA/SHA-512                    [RFC5702]
  "ECC-GOST"           = 12;      # GOST R 34.10-2001              [RFC5933]
  ECDSAP256SHA256      = 13;      # ECDSA Curve P-256 with SHA-256 [RFC6605]
  ECDSAP384SHA384      = 14;      # ECDSA Curve P-384 with SHA-384 [RFC6605]
  INDIRECT             = 252;     # Reserved for indirect keys     [RFC4034]
  PRIVATEDNS           = 253;     # Private algorithm              [RFC4034]
  PRIVATEOID           = 254;     # Private algorithm OID          [RFC4034]
}

