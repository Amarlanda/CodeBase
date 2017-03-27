$username = "UK\-ADMIN-ALANDA"
$password = "Dragon102"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

$length = 7

$set = "ABCDEFGHIJLKMNOPQRSTUVWXYZY0123456789".ToCharArray()
$result = ""
for ($x = 0; $x -lt $Length; $x++) {
    $result += $set | Get-Random
    }
    $Name = "UK$($result)"
    $name 
   # $name = "UKPK1DX14"

Rename-Computer -newname $Name
add-computer -Domain UK.KWORLD.KPMG.COM -NewName $Name -OUPath "OU=Audit,OU=Persistent,OU=GDV52,OU=VDI,OU=Clients,DC=uk,DC=kworld,DC=kpmg,DC=com" -Credential $cred


#$Computer = Get-WmiObject Win32_ComputerSystem
#$Computer.Rename("$name", $cred)

