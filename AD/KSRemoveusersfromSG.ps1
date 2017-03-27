$UserList | ForEach-Object {
  $UserDN = Get-KSADUser -SamAccountName $_ | Select-Object -ExpandProperty DistinguishedName
  Get-KSADGroup -LdapFilter "(&(member=$UserDN)(|(name=UK-SG UKAudit VDI)(name=UK-SG UKAudit1 VDI)(name=UK-SG UKAudit2 VDI)(name=UK-SG UKAudit3 VDI)(name=UK-SG UKAudit4 VDI)))" |
    ForEach-Object {
      Write-Host "Removing $UserDN from $($_.Name)"
      #Remove the member
      $_.GetDirectoryEntry().Remove("LDAP://$UserDN")
    }
  }
