$username = "uk\-oper-alanda"
$password = "Dragon102"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

Start-Process powershell -Credential $cred -NoNewWindow -ArgumentList "Start-Process powershell.exe -verb runas"

start-sleep -s 2