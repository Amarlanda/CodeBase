function Get-KSLocalUser {
  # .SYNOPSIS
  #   Gets local user accounts from a computer.
  # .DESCRIPTION
  #   Get-KSLocalUser returns all local user accounts on a machine, including all properties exposed by the WinNT provider. 
  # .PARAMETER ComputerName
  #   The name of the ComputerName to execute against. By default the function uses the local system.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .PARAMETER Name
  #   Get a specific user account from the computer (supports wildcards).
  # .EXAMPLE
  #   Get-LocalUser | Select-Object SystemName, Name, Class, Description
  #
  #   Get users from the local computer.
  # .EXAMPLE
  #   Get-Content ServerList.txt | ForEach-Object { Get-LocalUser -ComputerName $_ }
  #
  #   Get local users from each.
  # .EXAMPLE
  #   Get-KSADComputer -OperatingSystem "Windows 7*" | Get-LocalGroupMember
  #
  #   Get local users from all computers in Active Directory running Windows 7.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/11/2014 - Chris Dent - Added check to prevent the script executing against Domain Controllers.
  #     25/09/2014 - Chris Dent - Added Type and Path properties to the return object.
  #     25/07/2014 - Chris Dent - First release.
 
  [CmdLetBinding()]
  param(
    [String]$Name = '*',

    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias("DnsHostName")]
    [String]$ComputerName = $env:ComputerName,
    
    [PSCredential]$Credential
  )

  process {
    $DirectoryEntryParams = @{}
    if ($Credential) { $DirectoryEntryParams.Add("Credential", $Credential) }
  
    # Check to see if the account looks like a Domain Controller or not.
    # Only Domain Controllers can hold Computers as account database objects. A Domain Controller will contain itself as an account database object.
    $IsDomainController = $false
    $DomainControllerDirectoryEntry = NewKSADDirectoryEntry -DirectoryPath "WinNT://$ComputerName/$($ComputerName -replace '\..+$')$" @DirectoryEntryParams
    if ($DomainControllerDirectoryEntry.Path) {
      $IsDomainController = $true
    }
  
    if ($IsDomainController) {
      Write-Verbose "Get-KSLocalGroup should not be used on a Domain Controller."
    } else {
      $DirectoryEntry = NewKSADDirectoryEntry -DirectoryPath "WinNT://$ComputerName" @DirectoryEntryParams
    
      $DirectoryEntry.PSBase.Children | Where-Object { $_.Class -eq "user" -and $_.Name -like $Name } | ForEach-Object {
        $Object = ConvertFromKSADPropertyCollection $_.Properties -ObjectPath $_.Path -ObjectType $_.Class
        $Object.PSObject.TypeNames.Add("KScript.Local.User")
        
        # Property: DirectoryEntry
        $Object | Add-Member DirectoryEntry -MemberType NoteProperty -Value $_
        
        $Object
      }
    }
  }
}