$StringMatch = "EAudit*"
$objectcomputer = "UKVDDGV52023"



gci "\\$objectcomputer\c$" -fo -r -fi $StringMatch -ea 0 | select *

"{0:N2}" -f $((gci $(gci "\\$objectcomputer\c$" -fo -r -fi $StringMatch -ea 0 ).fullname -r -fo -ea 0 | measure-object -property length -sum ).sum / 1gb)

$StringMatch = "Users\All Users\Symantec\Symantec Endpoint Protection"
"{0:N2}" -f $((gci $(gci "\\$objectcomputer\*" -fo -r -fi $StringMatch -ea 0 ).fullname -r -fo -ea 0 | measure-object -property length -sum ).sum / 1gb)

$Searcher = [adsisearcher] [adsi] "LDAP://OU=VDI,OU=Clients,DC=uk,DC=kworld,DC=kpmg,DC=com"
$Searcher.PageSize = 1000
$Searcher.filter = "(&(objectClass=computer) (CN=*))"
$res = $searcher.findall()
$res.count

$VDIData =@()
$results =@()
$OLDCOMPS=@()

$res| %{ $_

        $objComputer = $_.properties.name
       
    ##Test Computer is live from AD
    IF((Test-Connection -CN $objComputer -Count 1 -BufferSize 16 -Quiet) -match 'True') {
         
        $EnumGrp = "Administrators"
        $objGroup =[ADSI]"WinNT://$objComputer/$EnumGrp"
        $members = @($objGroup.psbase.Invoke("Members"))

        $AllAdminGroups = @()

            foreach ($member in $members) { 
            
            $AdminGroup = $member.GetType().InvokeMember('Name','GetProperty',$null,$member,$null) 
            $AllAdminGroups  +=  $AdminGroup
            }

		    $AdminGroupString = $AllAdminGroups -join ", "
            $disk = Get-WmiObject win32_logicaldisk -computername $objComputer | Where-Object { $_.DriveType -eq 3 }
            #C:\ProgramData\EAudit*
            #C:\Users\All Users\Symantec\Symantec Endpoint Protection*
            

    } ELSE {
            
      $OLDCOMPS += $bla
            
    }

            $disk | foreach-object {
            $results += New-Object PsObject -Property ([Ordered]@{

                VMname =$_.systemname;
                Type= $_.VolumeName;
                Freespace =$("{0:N2}" -f $($_.FreeSpace / 1073741824 ) + "GB")
                Disk = $_.DeviceID ;
                Administrators =$AdminGroupString;
            })

        }
      
  }
  
  $results | ft -AutoSize
  $results | Export-Csv -NoTypeInformation C:\test\vdiaudit.csv
  $OLDCOMPS | ft -AutoSize
  $OLDCOMPS | export-csv -noTypeinformation C:\test\oldcompsdeletfromAD.csv
  

