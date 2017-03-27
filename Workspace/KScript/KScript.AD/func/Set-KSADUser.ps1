function Set-KSADUser {
  # .SYNOPSIS
  #   Set attributes on a user account.
  # .DESCRIPTION
  #   Set-KSADUser allows specific attributes to be set on a users account.
  #
  #   Set-KSADUser implements a number of static parameters documented in this help entry. In addition to this Set-KSADUser dynamically adds properties based on <TBC>.
  # .PARAMETER c
  #   The country/region in the address of the user. The country/region is represented as a 2-character code based on ISO-3166.
  # .PARAMETER co
  #   The country/region in which the user is located.
  # .PARAMETER department
  #   Contains the name for the department in which the user works.
  # .PARAMETER description
  #   Contains the description to display for an object. This value is restricted as single-valued for backward compatibility in some cases but is allowed to be multi-valued in others.
  # .PARAMETER displayName
  #   The display name for an object. This is usually the combination of the users first name, middle initial, and last name.
  # .PARAMETER employeeID
  #   The ID of an employee.
  # .PARAMETER givenName
  #   Contains the given name (first name) of the user.
  # .PARAMETER Identity
  #   An objectGUID, DistinguishedName or UserPrincipalName which can be used to uniquely identify an account across a forest.
  # .PARAMETER ipPhone
  #   The TCP/IP address for the phone. Used by Telephony.
  # .PARAMETER l
  #   Represents the name of a locality, such as a town or city.
  # .PARAMETER otherTelephone
  #   A list of alternate office phone numbers.
  # .PARAMETER PassThru
  #   By default, Set-KSADUser does not return any output. The input object, or DirectoryEntry object, may be returned using this parameter.
  # .PARAMETER physicalDeliveryOfficeName
  #   Contains the office location in the user's place of business.
  # .PARAMETER postalCode
  #   The postal or zip code for mail delivery.
  # .PARAMETER sAMAccountName
  #   The logon name used to support clients and servers running earlier versions of the operating system, such as Windows NT 4.0, Windows 95, Windows 98, and LAN Manager. This attribute must be less than 20 characters to support earlier clients.
  # .PARAMETER sn
  #   This attribute contains the family or last name for a user.
  # .PARAMETER st
  #   The name of a user's state or province.
  # .PARAMETER streetAddress
  #   The street address.
  # .PARAMETER telephoneNumber
  #   The primary telephone number.
  # .PARAMETER title
  #   Contains the user's job title. This property is commonly used to indicate the formal job title, such as Senior Programmer, rather than occupational class, such as programmer. It is not typically used for suffix titles such as Esq. or DDS.
  # .INPUTS
  #   System.String
  #   KScript.AD.User
  # .OUTPUTS
  #   KScript.AD.User
  # .EXAMPLE
  #   Get-KSADUser -SamAccountName SomeUser | Set-KSADUser -IPPhone 123456789
  # 
  #   Change the existing IPPhone value for username.
  # .EXAMPLE
  #   Set-KSADUser -Identity user@domain.example -TelephoneNumber "+44 (0) 123 456789"
  #
  #   Update the phone number for user@domain.example.
  # .EXAMPLE
  #   Set-KSADUser -Identity user@domain.example -IPPhone $null
  #
  #   Clear the current value of IPPhone for user@domain.example.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     05/08/2014 - Chris Dent - Bug fix (string binding preventing $null check)
  #     04/08/2014 - Chris Dent - Modified parameter set. Implemented WhatIf and PassThru support. Added support for clearing attributes.
  #     07/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ByIdentity')]
  param(
    [Parameter(Position = 1, ParameterSetName = 'ByIdentity')]
    [ValidateNotNullOrEmpty()]
    [String]$Identity,
   
    [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
    [ValidateScript( { $_.PSObject.TypeNames -contains 'KScript.AD.User' } )]
    $KSADUser,
   
    [Nullable``1[[DateTime]]]$accountExpires,
   
    [Alias('CountryCode')]
    [String]$c,

    [Alias('Country')]
    [String]$co,
    
    [String]$department,
    
    [String]$description,
    
    [String]$displayName,
    
    [String]$employeeID,
    
    [String]$givenName,
    
    [String]$ipPhone,
    
    [Alias('City')]
    [String]$l,
  
    [String]$otherTelephone,

    [Alias('Office')]
    [String]$physicalDeliveryOfficeName,
    
    [String]$postalCode,

    [String]$sAMAccountName,
    
    [String]$sn,
    
    [String]$st,
    
    [String]$streetAddress,

    [String]$telephoneNumber,
    
    [String]$title,
    
    [Switch]$PassThru
  )
  
  dynamicparam {
    # extensionAttributes (including KPMG aliasing)
  }
  
  begin {
    if ($pscmdlet.ParameterSetName -eq 'ByIdentity') {
      $Params = @{}
      $psboundparameters.Keys | Where-Object { $_ -ne 'Identity' } | ForEach-Object {
        $Params.Add($_, $psboundparameters[$_])
      }
    
      Get-KSADUser -Identity $Identity | Set-KSADUser @Params
    }
  }
  
  process {
    $RequestedChanges = $psboundparameters.Keys | Where-Object { $_ -cmatch '^[a-z]' }
  
    if (-not $RequestedChanges) {
    
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "At least one attribute change must be requested when using Set-KSADUser."),
        "ArgumentException",
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
      
    }

    if ($KSADUser) {
      $Changes = $RequestedChanges | ForEach-Object {
        if ($KSADUser.$_ -ne $psboundparameters[$_]) {
          $_
        } else {
          Write-Verbose "Set-KSADUser: Attempted to set $_, but the value was already set."
        }
      }
    
      if ($Changes) {
        $ADUser = $KSADUser.GetDirectoryEntry()

        $Changes | ForEach-Object {
          $AttributeName = $_
          $Value = $psboundparameters[$_]

          # accountExpires handler
          
          if ($pscmdlet.ShouldProcess("Setting $AttributeName on $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
            if ($Value -eq $null -or $Value -eq "") {
              $ADUser.PutEx([KScript.AD.IADSControlCode]::Clear, $AttributeName, 0)
            } else {
              $ADUser.Put($AttributeName, $Value)
            }
          }
        }
          
        try {
          if ($pscmdlet.ShouldProcess("Saving changes to $($KSADUser.SamAccountName) ($($KSADUser.objectGUID))")) {
            $ADUser.SetInfo()
          }
        } catch {
          Write-Error $_.Exception.Message.Trim() -Category OperationStopped
        }
      }
    }
    
    if ($PassThru) {
      $KSADUser | Get-KSADUser
    }
  }
}