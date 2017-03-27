
<#$pool = get-pool | ? { $_.pool_id -like "*ukau*" }
$vdis = $pool | Get-DesktopVM

$decom = import-csv c:\vdi\migration4.csv
$decom | % { 
     
    $firstobject = $_
    $vdis | Where-Object { $_.name -like $firstobject.newvdi } | % {$vdi = $_ }
    $_.displayname = $vdi.user_displayname
      
}
$data | ? { $_.newvdi} |  sort newvdi
#>

$searcher = [adsisearcher] [adsi] "LDAP://UK"
$username = "uktpalanda"

$searcher.filter = "(&(objectClass=user) (CN=$($username)))"
$ADobj = $searcher.findone().GetDirectoryEntry()

$searcher.filter = "(&(member= $($ADobj.distinguishedName))(|(name=UK-SG UKAudit VDI)(name=UK-SG UKAudit1 VDI)(name=UK-SG UKAudit2 VDI)(name=UK-SG UKAudit3 VDI)(name=UK-SG UKAudit4 VDI)))" 
$ADobj = $searcher.findall()
$ADobj | % {

Write-Host "Removing $username from $($_)"
# Remove the member
# $_.GetDirectoryEntry().Remove("LDAP://$UserDN")
}
  