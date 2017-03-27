# .SYNOPSIS
#   Create an AccountType property using the rules described below.
# .DESCRIPTION
#   Internal use only.
#
#   AccountType is a calculated, KPMG specific, property based on the application of a set of rules against a number of user account properties.
#
#   Rules:
#   
#     1.  If SamAccountType is not UserObject set AccountType to SamAccountType.
#     2.  If the objectSID is that of a built-in account set AccountType to BuiltIn.
#     3.  If the SamAccountName is in the hard-coded list of automatically added accounts or starts with SystemMailbox{ set AccountType to AutomaticallyAdded.
#     4.  If the SamAccountName matches ^(admin\S+$|-admin-) set AccountType to Admin.
#     5.  If the SamAccountName matches ^-gen- set AccountType to Generic.
#     6.  If the SamAccountName matches ^(uk-?fm|JM-) set AccountType to Mailbox.
#     7.  If the SamAccountName matches ^-oper- set AccountType to Oper.
#     8.  If the SamAccountName matches ^(uk)?-svc-? set AccountType to Service.
#     9.  If the SamAccountName matches ^-ukat- set AccountType to Template.
#     10. If the SamAccountName matches ^-test- set AccountType to Test
#     11. If the SamAccountName matches ^uk[st]p set the AccountType to User-TempOrServiceProvider
#     12. If nothing else has matched, set the AccountType to User.
#     13. If the AccountType is user, but the display name contains no spaces (does not look like an ordinary user account), reset the AccountType value to Unknown.
#
# .PARAMETER ADObject
#   An ADObject constructed by ConvertFromKSADPropertyCollection.
# .INPUTS
#   System.Object
# .OUTPUTS
#   System.Object
# .NOTES
#   Author: Chris Dent
#   Team:   Core Technologies
#
#   Change log:
#     01/10/2014 - Chris Dent - First release  
 
[CmdLetBinding()]
param(
  $ADObject
)

if ($ADObject.Type -eq 'user') {
  $BuiltIn = "500",   # Administraotr
             "501",   # Guest
             "502",   # krbtgt
             "512",   # DomainAdmin
             "513",   # DomainUsers
             "514",   # DomainGuest
             "515",   # Computers
             "516",   # Controllers
             "517",   # CertAdmin
             "518",   # SchemaAdmin
             "519",   # EnterpriseAdmin
             "520",   # PolicyAdmin
             "553"    # RasAndIasServers
  $AutomaticallyAdded = "TsInternetUser"

  $ADObject | Add-Member AccountType -MemberType ScriptProperty -Value {
    if ($this.SamAccountType -ne 'UserObject') {
      $AccountType = $this.SamAccountType -replace 'Account$'
    } elseif (($this.objectSID.Value.ToString() -replace '^.+-') -in $BuiltInAccounts) {
      $AccountType = 'BuiltIn'
    } elseif ($this.sAMAccountName -in $AutomaticallyAdded -or $this.Name -match '^SystemMailbox\{') {
      $AccountType = 'AutomaticallyAdded'
    } else {
      $AccountType = switch -regex ($this.SamAccountName) {
        '^(admin\S+$|-admin-)' { 'Admin'; break }
        '^-gen-'               { 'Generic'; break }
        '^(uk-?fm|JM-)'        { 'Mailbox'; break }
        '^-oper-'              { 'Oper'; break }
        '^(uk)?-svc-?'         { 'Service'; break }
        '^-ukat-'              { 'Template'; break }
        '^-test-'              { 'Test'; break }
        '^uk[st]p'             { 'User-TempOrServiceProvider'; break }
        default                { 'User' }
      }
    }
    if ($AccountType -eq 'User' -and $this.DisplayName -match '^\S+$') {
      $AccountType = 'Unknown'
    }
    $AccountType
  }
}

return $ADObject