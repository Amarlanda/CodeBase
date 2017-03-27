#
# Module loader for KScript.DnsResolver
#
# Author: Chris Dent
# Team:   Core Technologies
#
# Change log:
#   13/01/2015 - Chris Dent - First release.

# Static enumerations
[Array]$Enum = 'KScript.DnsResolver.AFSDBSubType',
               'KScript.DnsResolver.ATMAFormat',
               'KScript.DnsResolver.CertificateType',
               'KScript.DnsResolver.DigestType',
               'KScript.DnsResolver.EDnsOptionCode',
               'KScript.DnsResolver.EDnsSECOK',
               'KScript.DnsResolver.EncryptionAlgorithm',
               'KScript.DnsResolver.Flags',
               'KScript.DnsResolver.IanaAddressFamily',
               'KScript.DnsResolver.IPSECAlgorithm',
               'KScript.DnsResolver.IPSECGatewayType',
               'KScript.DnsResolver.KEYAC',
               'KScript.DnsResolver.KEYNameType',
               'KScript.DnsResolver.KEYProtocol',
               'KScript.DnsResolver.LLQErrorCode',
               'KScript.DnsResolver.LLQOpCode',
               'KScript.DnsResolver.MessageCompression',
               'KScript.DnsResolver.MSDNSOption',
               'KScript.DnsResolver.NSEC3Flags',
               'KScript.DnsResolver.NSEC3HashAlgorithm',
               'KScript.DnsResolver.QR',
               'KScript.DnsResolver.RCode',
               'KScript.DnsResolver.RecordClass',
               'KScript.DnsResolver.RecordType',
               'KScript.DnsResolver.SSHAlgorithm',
               'KScript.DnsResolver.SSHFPType',
               'KScript.DnsResolver.TKEYMode',
               'KScript.DnsResolver.WINSMappingFlag'

if ($Enum.Count -ge 1) {
  New-Variable DnsResolverModuleBuilder -Value (New-KSDynamicModuleBuilder KScript.DnsResolver -UseGlobalVariable $false) -Scope Script
  $Enum | ForEach-Object {
    Import-Module "$psscriptroot\enum\$_.ps1"
  }
}

# Private functions
[Array]$Private = 'ConvertFromKSDnsDomainName',
                  'ConvertToKSDnsDomainName',
                  'NewKSDnsMessage',
                  'NewKSDnsMessageHeader',
                  'NewKSDnsMessageQuestion',
                  'NewKSDnsOPTRecord',
                  'NewKSDnsSOARecord',
                  'ReadKSDnsA6Record',
                  'ReadKSDnsAAAARecord',
                  'ReadKSDnsAFSDBRecord',
                  'ReadKSDnsAPLRecord',
                  'ReadKSDnsARecord',
                  'ReadKSDnsATMARecord',
                  'ReadKSDnsCERTRecord',
                  'ReadKSDnsCharacterString',
                  'ReadKSDnsCNAMERecord',
                  'ReadKSDnsDHCIDRecord',
                  'ReadKSDnsDLVRecord',
                  'ReadKSDnsDNAMERecord',
                  'ReadKSDnsDNSKEYRecord',
                  'ReadKSDnsDSRecord',
                  'ReadKSDnsEIDRecord',
                  'ReadKSDnsGPOSRecord',
                  'ReadKSDnsHINFORecord',
                  'ReadKSDnsHIPRecord',
                  'ReadKSDnsIPSECKEYRecord',
                  'ReadKSDnsISDNRecord',
                  'ReadKSDnsKEYRecord',
                  'ReadKSDnsKXRecord',
                  'ReadKSDnsLOCRecord',
                  'ReadKSDnsMBRecord',
                  'ReadKSDnsMDRecord',
                  'ReadKSDnsMessage',
                  'ReadKSDnsMessageHeader',
                  'ReadKSDnsMessageQuestion',
                  'ReadKSDnsMFRecord',
                  'ReadKSDnsMGRecord',
                  'ReadKSDnsMINFORecord',
                  'ReadKSDnsMRRecord',
                  'ReadKSDnsMXRecord',
                  'ReadKSDnsNAPTRRecord',
                  'ReadKSDnsNINFORecord',
                  'ReadKSDnsNSAPRecord',
                  'ReadKSDnsNSEC3PARAMRecord',
                  'ReadKSDnsNSEC3Record',
                  'ReadKSDnsNSECRecord',
                  'ReadKSDnsNSRecord',
                  'ReadKSDnsNULLRecord',
                  'ReadKSDnsNXTRecord',
                  'ReadKSDnsOPTRecord',
                  'ReadKSDnsPTRRecord',
                  'ReadKSDnsPXRecord',
                  'ReadKSDnsResourceRecord',
                  'ReadKSDnsRKEYRecord',
                  'ReadKSDnsRPRecord',
                  'ReadKSDnsRRSIGRecord',
                  'ReadKSDnsRTRecord',
                  'ReadKSDnsSIGRecord',
                  'ReadKSDnsSINKRecord',
                  'ReadKSDnsSOARecord',
                  'ReadKSDnsSPFRecord',
                  'ReadKSDnsSRVRecord',
                  'ReadKSDnsSSHFPPRecord',
                  'ReadKSDnsTARecord',
                  'ReadKSDnsTKEYRecord',
                  'ReadKSDnsTSIGRecord',
                  'ReadKSDnsTXTRecord',
                  'ReadKSDnsUnknownRecord',
                  'ReadKSDnsWINSRecord',
                  'ReadKSDnsWINSRRecord',
                  'ReadKSDnsWKSRecord',
                  'ReadKSDnsX25Record'

if ($Private.Count -ge 1) {
  $Private | ForEach-Object {
    Import-Module "$psscriptroot\func-priv\$_.ps1"
  }
}

# Public functions
[Array]$Public = 'Add-KSInternalDnsCacheRecord',
                 'Get-KSDns',
                 'Get-KSDnsServerList',
                 'Get-KSInternalDnsCacheRecord',
                 'Initialize-KSInternalDnsCache',
                 'Remove-KSInternalDnsCacheRecord',
                 'Update-KSInternalRootHints'

if ($Public.Count -ge 1) {
  $Public | ForEach-Object {
    Import-Module "$psscriptroot\func\$_.ps1"
  }
}

# Resolver (Message): Initialize the DNS cache for Get-KSDns
Initialize-KSInternalDnsCache

# Resolver (Message): Set a variable to store TC state.
New-Variable KSDnsTCEndFound -Scope Script -Value $false

