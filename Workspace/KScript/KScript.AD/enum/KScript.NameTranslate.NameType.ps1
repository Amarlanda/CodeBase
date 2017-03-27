New-KSEnum -ModuleBuilder $Script:ADModuleBuilder -Name "KScript.NameTranslate.NameType" -Type "Byte" -Members @{
  RFC1779              = 1     # Name format as specified in RFC 1779. For example, "CN=Jeff Smith,CN=users,DC=Fabrikam,DC=com".
  Canonical            = 2     # Canonical name format. For example, "Fabrikam.com/Users/Jeff Smith".
  NT4                  = 3     # Account name format used in Windows. For example, "Fabrikam\JeffSmith".
  DisplayName          = 4     # Display name format. For example, "Jeff Smith".
  DomainSimple         = 5     # Simple domain name format. For example, "JeffSmith@Fabrikam.com".
  EnterpriseSimple     = 6     # Simple enterprise name format. For example, "JeffSmith@Fabrikam.com".
  GUID                 = 7     # Global Unique Identifier format. For example, "{95ee9fff-3436-11d1-b2b0-d15ae3ac8436}".
  Unknown              = 8     # Unknown name type. The system will estimate the format. This element is a meaningful option only with the IADsNameTranslate.Set or the IADsNameTranslate.SetEx method, but not with the IADsNameTranslate.Get or IADsNameTranslate.GetEx method.
  UserPrincipalName    = 9     # User principal name format. For example, "JeffSmith@Fabrikam.com".
  ExtendedCanonical    = 10    # Extended canonical name format. For example, "Fabrikam.com/Users Jeff Smith".
  ServicePrincipalName = 11    # Service principal name format. For example, "www/www.fabrikam.com@fabrikam.com".
  SIDorSIDHistoryName  = 12    # A SID string, as defined in the Security Descriptor Definition Language (SDDL), for either the SID of the current object or one from the object SID history. For example, "O:AOG:DAD:(A;;RPWPCCDCLCSWRCWDWOGA;;;S-1-0-0)" For more information, see Security Descriptor String Format.
}