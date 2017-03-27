

$searcher = [adsisearcher] [adsi] "LDAP://UK"
$SecuirtyGroup = "UK-Sg UK Advisory-KCRC"
$searcher.filter = "(&(objectClass=group) (CN=$SecuirtyGroup))"
$Group = $searcher.findone().GetDirectoryEntry()

write-host 'SecuirtyGroup = '$Group.distinguishedName

    write-host "Menbers"                                                #
     write-host "-------"
    $group.member | % {$_ -replace "(CN=)(.*?),.*",'$2'} | Sort | export-csv -notypeinformation        #| ?{$_ -like "*$Username*"}             #  This displays members of this group....
    write-host "This SG has $($group.member.count) Menbers"
    
    
    #$Group.memberof | % {$_ -replace "(CN=)(.*?),.*",'$2'}| Sort-Object # this displays whats SGs this SG is a member of... 
    