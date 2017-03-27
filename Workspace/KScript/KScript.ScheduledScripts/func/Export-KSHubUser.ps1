function Export-KSHubUser {
  # .SYNOPSIS
  #   Export a list of users for the Hub.
  # .DESCRIPTION
  #   Export-KSHubUser exports the membership of two groups and sends each as an attachment to a mail.
  #
  #   Service owner:   Gaynor Hayes / Thore Gaynor Hayes (The Hub)
  #   PREMAS number:   
  #   Service account: uk-svc-auto-eaudit
  #   Schedule:        Monthly
  # 
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     21/11/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [String]$WorkingDirectory = "F:\temp"
  )
  
  Write-KSLog "Starting $($myinvocation.MyCommand)" -StartTranscript

  Get-KSADGroup "UK-SG TibbrUser" |
    Get-KSADGroupMember -Properties mail, givenName, sn, employeeID -SizeLimit 0 |
    Select-Object mail, givenName, sn, employeeID |
    Export-Csv "$WorkingDirectory\tibbruser.csv" -NoTypeInformation
    
  Get-KSADGroup "UK-SG UKHubException" |
    Get-KSADGroupMember -Properties mail, givenName, sn, employeeID -SizeLimit 0 |
    Select-Object mail, givenName, sn, employeeID |
    Export-Csv "$WorkingDirectory\hubexception.csv" -NoTypeInformation
  
  Send-MailMessage -From (Get-KSSetting KSUsersEmail -ExpandValue) -To "Gaynor.Hayes@KPMG.co.uk" -Subject "TibbrUser and Hub exception export" -Attachments "$WorkingDirectory\tibbruser.csv", "$WorkingDirectory\hubexception.csv"

  Write-KSLog "Finished $($myinvocation.MyCommand)" -StopTranscript
}