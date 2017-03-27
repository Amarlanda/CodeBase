Get-View -ViewType "VirtualMachine" -Property @("Name", "Config.GuestFullName", "Guest.GuestFullName") |`
 Where-Object {($_.Config.GuestFullName -ne $_.Guest.GuestFullName) -and `
  ($_.Guest.GuestFullName -ne $null)} | `
 Select-Object -Property Name, @{N="Configured OS";E={$_.Config.GuestFullName}}, `
  @{N="Running OS";E={$_.Guest.GuestFullName}} | `
 Format-Table -AutoSize