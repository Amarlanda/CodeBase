;----------------- request.inf -----------------
[Version]

Signature= $Windows NT$

[NewRequest]

Subject = "CN=virtualdesktop.uk.kworld.kpmg.com, OU=KPMG, O=KPMG, L=Watford, S=Watford, C=UK" ; replace attributes in this line using example below
KeySpec = 1
KeyLength = 2048
; Can be 2048, 4096, 8192, or 16384.
; Larger key sizes are more secure, but have
; a greater impact on performance.
Exportable = TRUE
FriendlyName = vdm
MachineKeySet = TRUE
SMIME = False
PrivateKeyArchive = FALSE
UserProtected = FALSE
UseExistingKeySet = FALSE
ProviderName = Microsoft RSA SChannel Cryptographic Provider
ProviderType = 12
RequestType = PKCS10
KeyUsage = 0xa0

[EnhancedKeyUsageExtension]

OID=1.3.6.1.5.5.7.3.1 ; this is for Server Authentication

[RequestAttributes]

  
SAN= UKVMAPP136.uk.kworld.kpmg.com&UKVMAPP137.uk.kworld.kpmg.com
;-----------------------------------------------