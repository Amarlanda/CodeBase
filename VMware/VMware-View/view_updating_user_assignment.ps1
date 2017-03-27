
##On computer##


#Open Excel show only colums  uk ID, New Machine, SID
Import-Module .\QuestAD\Quest.ActiveRoles.ArsPowerShellSnapIn.dll ##import module


$pool = get-pool | ? { $_.pool_id -eq "UKWGDV52-P-A"}
$VDIs = $pool | get-desktopvm

$Migration = import-csv C:\Amar\Migration5.csv | select *, sid

$migration | % { 

$($currentuser = Get-QADUser -SAMAccountName $_.username) | Add-QADGroupMember “UK-SG VDI UKWGDV52-P-A”
$_.sid = $currentuser.sid
write-host  "SID from Quest $($_.sid ) "#$(Get-QADUser -sid $($_.sid )"
$NewVDI = $_.NewVDI
write-host  "NewVDI: $NewVDI "
$sid = $_.SID

   $MatchingVDI = $VDIs | Where-Object { $_.Name -eq $NewVDI } | % { ##update aissgment##
   write-host "new vdi: $($NewVDI) matching vdi $($_.name)-Machine_id $($_.machine_id) -sid $($sid)" ## just for reference
   Remove-UserOwnership -machine_id $_.machine_id
   Update-UserOwnership -Machine_id $_.machine_id -sid $sid 
   } 

}
$migration | Export-Csv c:\Amar\Migration5.csv -NoTypeInformation ##export to CSV}
#########
##check##
#########

$pool = get-pool | ? { $_.pool_id -eq "UKWGDV52-P-A"}
$VDIs = $pool | get-desktopvm
$vdis = $vdis | Get-DesktopVM
$vdis = $vdis | ? { $_.user_displayname }
$Migration | % {
   $NewVDI = $_.NewVDI
   $username =  $_.username
   $MatchingVDI = $VDIs | Where-Object { $_.Name -eq $NewVDI }
   
   write-host "Machine: $($MatchingVDI.name) user: $($MatchingVDI.user_displayname)"
   #$username

   }


# So instead of horrible inefficient ways... Create a keyed list which lets us get from VDIName to MachineID.
# Yay! HashTable time.
$VMNameToMachineID = @{}
$VDIs | ForEach-Object {
  # Add the machine name to the hash table with the machine ID as the value. Let's us jump from the machine name to the machine id with no extra looping.
  $VMNameToMachineID.Add($_.Name, $_.machine_id)
}

# And with that we only really need
$Migration | Select-Object *, @{Name='NewMachineID';Expression={ $VMNameToMachineID[$_.NewVDI] }}
$StopWatch.Stop()
$StopWatch



## remove-ownership ### old enviorment ##  
$pool = get-pool | ? { $_.pool_id -like "*ukau*" }
$vdis = $pool | Get-DesktopVM


$decom = get-content C:\Amar\decom.txt

$decom | % { $decomvm = $_
               write-host "current checking VM is $($decomvm)"
            $vdis | ? { $($_.name) -eq $($decomvm) }| % {
            write-host "Matched VM $($_.name) with $($decomvm)" 
            Remove-UserOwnership -machine_id $_.machine_id }
            }
    
