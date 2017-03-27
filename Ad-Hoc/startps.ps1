$username = "uk\-oper-alanda"
$password = "Dragon102"
$secstr = New-Object -TypeName System.Security.SecureString
$password.ToCharArray() | ForEach-Object {$secstr.AppendChar($_)}
$cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $secstr

start-process 'C:\windows\system32\WindowsPowerShell\v1.0\powershell.exe' -Credential $cred -NoNewWindow -ArgumentList "Start-Process powershell.exe -verb runas"