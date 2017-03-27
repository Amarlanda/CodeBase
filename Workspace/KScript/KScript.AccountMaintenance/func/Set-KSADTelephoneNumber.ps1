function Set-KSADTelephoneNumber {
  # .SYNOPSIS
  #   Set telephoneNumber information for an individual user (based on IPPhone).
  # .DESCRIPTION
  #   Set-KSADTelephoneNumber allows an administrator to set ipPhone, telephoneNumber and otherTelephones for an individual user.
  #
  #   If telephoneNumber and otherTelephones are not supplied they are dynamically generated using the ddi-mappings.xml file.
  # .PARAMETER Identity
  #   A userPrincipalName, distinguishedName or objectGUID for the user.
  # .PARAMETER KSADUser
  #   The result of a previous search for a user.
  # .PARAMETER IPPhone
  #   An IPPhone value.
  # .PARAMETER TelephoneNumber
  #   A telephoneNumber value.
  # .PARAMETER OtherTelephone
  #   An otherTelephone value.
  # .INPUTS
  #   KScript.AD.User
  #   System.String
  # .OUTPUTS
  #   KScript.Telephony.TelephoneInformation
  # .EXAMPLE
  #   Get-KSADUser SomeUser | Set-KSADTelephoneNumber -IPPhone 12345678
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     22/08/2014 - Chris Dent - Bug fix: otherTelephoneNumber changed to otherTelephone in return object.
  #     20/08/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'FromPipeline')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ByIdentity')]
    [String]$Identity,
    
    [Parameter(ValueFromPipeline = $true, ParameterSetName = 'FromPipeline')]
    $KSADUser,
    
    [Parameter(Mandatory = $true)]
    [String]$IPPhone,
    
    [String]$TelephoneNumber,

    [String]$OtherTelephone
  )
  
  begin {
    if ($psboundparameters.ContainsKey("Identity")) {
      $Params = @{IPPhone = $IPPhone}
      if ($psboundparameters.ContainsKey("telephoneNumber")) {
        $Params.Add("telephoneNumber", $TelephoneNumber)
      }
      if ($psboundparameters.ContainsKey("otherTelephone")) {
        $Params.Add("otherTelephone", $OtherTelephone)
      }
    
      Get-KSADUser -Identity $Identity | Set-KSADTelephoneNumber @Params
      
      break
    }
  }
  
  process {
    $Params = @{IPPhone = $IPPhone}
    $GeneratedNumber = Get-KSTelephoneNumber -IPPhone $IPPhone

    if ($psboundparameters.ContainsKey("telephoneNumber")) {
      $Params.Add("telephoneNumber", $TelephoneNumber)
    } elseif ($GeneratedNumber.Status -eq "OK") {
      $Params.Add("telephoneNumber", $GeneratedNumber.TelephoneNumber)
    }
    
    if ($psboundparameters.ContainsKey("otherTelephone")) {
      $Params.Add("otherTelephone", $otherTelephone)
    } elseif ($GeneratedNumber.Status -eq "OK") {
      $Params.Add("otherTelephone", $GeneratedNumber.otherTelephone)
    }
    
    if ($pscmdlet.ShouldProcess("Setting telephone number for $($KSADUser.UserPrincipalName)")) {
      $KSADUser | Set-KSADUser @Params
    }
    
    $KSADUser | Select-Object Name, DisplayName, UserPrincipalName, distinguishedName,
      @{n='PreviousIPPhone';e={ $KSADUser.ipPhone }},
      @{n='PreviousTelphoneNumber';e={ $KSADUser.TelephoneNumber }},
      @{n='PreviousOtherTelephone';e={ $KSADUser.OtherTelephone }},
      @{n='IPPhone';e={ $Params["IPPhone"] }},
      @{n='TelephoneNumber';e={ $Params["telephoneNumber"] }},
      @{n='OtherTelephone';e={ $Params["otherTelephone"] }}
  }
}