 [String[]]$users = "MMenicou", "YeeLi", "Tpatel1", "ukspmdogboe", "mtrimble",
"GPerikhanyan", "JYankova", "JSelby", "Ivine",
"OBurton", "TMcGlynn","Jkundel", "aramsay1", "ukspjnarebor", "ukspnodonnell",
"Dthakker1","JPerry1", "Kpamulapati", "Sebastianlee", "uktpalanda",
"tng3", "ukspehunt1", "Gbirk", "uktpskhera", "ukspajackson1", "ostevens1","Rhall8", "-oper-pford", "sharris",
"uksplshorter", "ukspmslimani", "Wkuan1", "DRios1","lhodges", "idownie", "jyankova", "ukspcwilliams", "NMcguffie", "tmahmood", "ukspamoustakas", "ukspbgower"

$userlist= @"
MMenicou
YeeLi
"@

$userlist.split().trim()| %{
Get-KSAccountLockoutLog -SamAccountName $_
} | Export-Csv "c:\test\AccountLockouts.csv" -NoTypeInformation
