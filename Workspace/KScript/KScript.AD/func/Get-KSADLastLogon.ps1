function Get-KSADLastLogon {
  # .SYNOPSIS
  #   Get the value of lastLogon for user.
  # .DESCRIPTION
  #   Get-KSADLastLogon requests the lastLogon attribute from every Domain Controller in the current domain, returning the most recent.
  #
  #   The lastLogon attribute is not replicated between Domain Controllers in Active Directory. lastLogonTimeStamp is available for broad information, however by default lastLogonTimeStamp is only updated once it becomes 9-14 days old (and therefore may be out of date).
  # .PARAMETER SamAccountName
  #   The username of the account to query.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.AD.LastUserLogon
  # .EXAMPLE
  #   Get-KSADLastLogon SomeUser
  # .LINK
  #   http://blogs.technet.com/b/askds/archive/2009/04/15/the-lastlogontimestamp-attribute-what-it-was-designed-for-and-how-it-works.aspx
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     10/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [ValidatePattern( '^[0-9A-Z\-_]+$' )]
    [String]$SamAccountName
  )
  
  begin {
    $DomainControllers = Get-KSADDomainController
    if (-not $DomainControllers) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "Unable to get Domain Controller list."),
        "ArgumentException",
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $Name)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
  }

  process {
    $LastLogonDate = Get-Date 01/01/1601
    $LastLogonServer = $null
    
    if (Get-KSADUser -SamAccountName $SamAccountName) {
      $Count = ([Array]$DomainControllers).Count; $i = 1
      
      $DomainControllers | ForEach-Object {
        Write-Progress "Getting lastLogon [$i/$Count]" -Status $_.Name -PercentComplete (($i / $Count) * 100); $i++
      
        $KSADUser = Get-KSADUser -SamAccountName $SamAccountName -ComputerName $_.Name      
        if ($KSADUser.lastLogon -gt $LastLogonDate) {
          $LastLogonDate = $KSADUser.lastLogon
          $LastLogonServer = $_.Name
        }
      }
    } else {
      Write-Warning "Get-KSADLastLogon: User account does not exist."
    }
    
    if ($KSADUser) {
      $LastUserLogon = $KSADUser | Select-Object Name, DisplayName, SamAccountName, @{n='LastLogonDate';e={ $LastLogonDate }}, @{n='LastLogonServer';e={ $LastLogonServer }}
      $LastUserLogon.PSObject.TypeNames.Add("KScript.AD.LastUserLogon")
      
      $LastUserLogon
    }
  }
}