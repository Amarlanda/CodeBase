$memberOf = ([ADSISEARCHER]"samaccountname=$($env:USERNAME)").Findall()

$memberof | % {$_.Properties.memberof -replace '^CN=([^,]+).+$','$1'}







if($memberOf -contains $group)
{
  "current user is member of $group"  
}
else
{
  "current user is not a member of $group"
}


UK_SG KSOP_KPMG_Checklist
UK_SG KSOP_SAPGUI
UK-SG KSOP_ ClipboardOn
UK-SG KSOP_ ClipboardOn_64bit
UK-SG KSOP_ COMPortOn
UK-SG KSOP_ COMPortOn_64bit
UK-SG KSOP_ eAudIT VDI Desktop client
UK-SG KSOP_ InternetExplorer_KGS
UK-SG KSOP_ LPTOn
UK-SG KSOP_ LPTOn_64bit
UK-SG KSOP_ OEMOn
UK-SG KSOP_ OEMOn_64bit
UK-SG KSOP_ PrinterOn
UK-SG KSOP_ PrinterOn_64bit
UK-SG KSOP_ R Drive
UK-SG KSOP_ T Drive
UK-SG KSOP_ TWAINOn
UK-SG KSOP_ TWAINOn_64bit
UK-SG KSOP_ U Drive
UK-SG KSOP_64Bit_UAT_Users
UK-SG KSOP_64Bit_UAT_Users_64bit
UK-SG KSOP_ABBYYFineReader
UK-SG KSOP_Acrobat_Pro
UK-SG KSOP_Acrobat_Pro_64bit
UK-SG KSOP_AdminForms_UAT
UK-SG KSOP_Alex
UK-SG KSOP_Audit_Office_2007
UK-SG KSOP_Audit_Users
UK-SG KSOP_Audit_Users_64bit
UK-SG KSOP_Caseware
UK-SG KSOP_Caseware_64bit
UK-SG KSOP_CF_Users
UK-SG KSOP_CRM
UK-SG KSOP_CRM_64bit
UK-SG KSOP_E-Courier {}
UK-SG KSOP_Eroom
UK-SG KSOP_Eroom_64bit
UK-SG KSOP_FS_Users
UK-SG KSOP_Graphics_Users
UK-SG KSOP_Graphics_Users_64bit
UK-SG KSOP_Idea
UK-SG KSOP_Idea_64bit
UK-SG KSOP_InternetExplorer7
UK-SG KSOP_KPMG_Checklist
UK-SG KSOP_Ms Access
UK-SG KSOP_Ms Access_64bit
UK-SG KSOP_Ms Office
UK-SG KSOP_Ms Office 2007
UK-SG KSOP_Ms Office 2007_64bit
UK-SG KSOP_Ms Office_64bit
UK-SG KSOP_MSProject
UK-SG KSOP_MSProject_64bit
UK-SG KSOP_MyLearning
UK-SG KSOP_MyLearning Access Only
UK-SG KSOP_MyLearning_64bit
UK-SG KSOP_Paperchase_Users
UK-SG KSOP_Paperchase_Users_64bit
UK-SG KSOP_Performance_Users
UK-SG KSOP_Performance_Users_64bit
UK-SG KSOP_PT_Users
UK-SG KSOP_Research_Users
UK-SG KSOP_Research_Users_64bit
UK-SG KSOP_Resource Management
UK-SG KSOP_Retain_Advisory_v5
UK-SG KSOP_Retain_Audit
UK-SG KSOP_Retain_Audit_64bit
UK-SG KSOP_Retain_TRC
UK-SG KSOP_SAP_BEXAnalyser
UK-SG KSOP_SAPPortal
UK-SG KSOP_SAPPortal_64bit
UK-SG KSOP_TS_Users
UK-SG KSOP_TS_Users_64bit
UK-SG KSOP_Visio
UK-SG KSOP_Visio_64bit
UK-SG KSOP_Workflow_Audit
UK-SG KSOP_Workflow_DE
UK-SG KSOP_Workflow_GSS
UK-SG KSOP_Workflow_PGT
UK-SG KSOP_Workflow_PT
UK-SG KSOP_Workflow_Research
UK-SG KSOP_XBRL
UK-SG KSOP_XBRL_64bit
UK-SG KSOP_XBRL_X64
UK-SG-KSOP_Admins
UK-SG-KSOP_AudioOn
UK-SG-KSOP_Dedicated_Users
UK-SG-KSOP_GPOReversal
UK-SG-KSOP_Independent_Users
UK-SG-KSOP_Project
UK-SG-KSOP_Restricted_Users
UK-SG-KSOP_Retain
UK-SG-KSOP_SAPSystem
UK-SG-KSOP_SL_Audit
UK-SG-KSOP_SL_Finance
UK-SG-KSOP_SL_Forensics
UK-SG-KSOP_SL_Performance
UK-SG-KSOP_SL_Transaction
UK-SG-KSOP_Support
UK-SG-KSOP_Users

    #$path = "http://ron.m4.net/cgi-bin/dwsrun?uBook/UBULOGIN.DWO&hidsys=ub1983"

    

function BulidShortcut
{

Param ($path, $name)


$des = join-path -path "$home"\Desktop\"$name"
[string]$des

$linkPath        = Join-Path ([Environment]::GetFolderPath("Desktop")) "$name"
$targetPath      = Join-Path ([Environment]::GetFolderPath("MyDocuments")) "...\run.exe"
$link            = (New-Object -ComObject WScript.Shell).CreateShortcut($linkPath)
$link.TargetPath = $targetPath
$link.save()


write-host "C:\Users\uktpalanda\Desktop\yes.lnk"
# Create a Calculator Shortcut with Windows PowerShell
$WshShell = New-Object -ComObject WScript.Shell
$Shortcut = $WshShell.CreateShortcut("$($des)")
$Shortcut.TargetPath = "$path"
$Shortcut.Save()

}

BulidShortcut "C:\_AJ.ink" "yes.ink"
#"http://ron.m4.net/cgi-bin/dwsrun?uBook/UBULOGIN.DWO&hidsys=ub1983.url" "bla bla"

#$Shortcut.TargetPath = ([Environment]::GetFolderPath("Desktop") + $name)
#