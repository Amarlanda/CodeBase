$VMwareKeyCSVs = "C:\Users\uktpalanda\Documents\VMware\KPMG Keys"

$i= 0
gci "$VMwareKeyCSVs" |? { $_.Attributes -ne "Directory"} | % { #loop through files

#Create Variable
New-Variable -Name $i -value $(import-csv -LiteralPath $_.FullName) -Description $($_.name.split(".")| select -First 1) -force  #import the CSV into a varible named by the filename. 
 $i++
}

function CompareObject{
Param(
  $obj1 = $args[0],
  $obj2 = $args[1],
  [String]$Action
)
begin{
    $result = Compare-Object -ReferenceObject $obj1 -DifferenceObject $obj2 -IncludeEqual -PassThru -Property key  
}

process{

    If ($Action -eq "Equal") {
        $result = $result | Where-Object {$_.SideIndicator -eq "=="}
    }

    if($Action -eq "OnlyInFirst") {
            $result = $result | Where-Object {$_.SideIndicator -eq "<="}
    }

    if($Action -eq "OnlyInSecond") {
    $result = $result | Where-Object {$_.SideIndicator -eq "=>"}
    }
    
    return $result, $bla
    }
}

#Normlaise the data as property on estate Keys is called 'License Key' and on the HP keys its called 'key'
$1  = $1 | select @{n='Key';e={$_.'License Key'}},*

$KeysInDashboard = CompareObject -obj1 $0 -obj2 $1 -Action Equal 


$KeysInHP = CompareObject -obj1 $0 -obj2 $2 -Action Equal 



<#
#Find Variable
get-Variable | ? {$_.Description -like "*vmware*"} | select name, description

#delete Varible
del variable:\VMwareLincenseDataAcrossTheEstatesCSV
#>
