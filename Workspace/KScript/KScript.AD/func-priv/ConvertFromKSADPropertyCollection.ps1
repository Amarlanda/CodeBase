function ConvertFromKSADPropertyCollection {
  # .SYNOPSIS
  #   Converts from a System.DirectoryServices.PropertyCollection to System.Management.Automation.PSCustomObject.
  # .DESCRIPTION
  #   Internal use only.
  #
  #   ConvertFromKSADPropertyCollection expands a PropertyCollection and attempts to convert primitive types where possible.
  #
  #   Specialised value converters are used for complex attributes.
  # .PARAMETER PropertyCollection
  #   The PropertyCollection to convert.
  # .INPUTS
  #   System.DirectoryServices.PropertyCollection
  # .OUTPUTS
  #   System.Management.Automation.PSCustomObject
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/12/2014 - Chris Dent - Modified AccountIsLockedOut to use System.DirectoryServices.AccountManagement.
  #     25/09/2014 - Chris Dent - Changed AccountIsLockedOut and AccountIsExpired
  #     19/09/2014 - Chris Dent - BugFix: Fixed AccountIsLockedOut check.
  #     02/07/2014 - Chris Dent - BugFix: PasswordNeverExpires (incorrect comparison operator).
  #     30/06/2014 - Chris Dent - Added AccountIsDisabled, AccountIsExpired, AccountIsLockedOut and PasswordNeverExpires properties.
  #     27/06/2014 - Chris Dent - Added Identity property.
  #     24/06/2014 - Chris Dent - Added support for simple lists.
  #     17/06/2014 - Chris Dent - Added Type property.
  #     13/06/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [ValidateScript( { $_ -is [DirectoryServices.ResultPropertyCollection] -or $_ -is [DirectoryServices.PropertyCollection] } )]
    $PropertyCollection,
    
    [String]$ObjectPath,
    
    [String]$ObjectType
  )
  
  process {
    $PSObject = New-Object PSObject
    # Loop through available keys in alphabetical order
    $PropertyCollection.Keys | ForEach-Object {
    
      $AttributeMap = Get-KSADAttributeMap $_

      $Name = $_

      $Value = $PropertyCollection[$_] | ForEach-Object {
        # Properties which need work before being displayed
        if ($AttributeMap) {
        
          # List handling

          if ($AttributeMap.AttributeType -is [Hashtable]) {
            if ($AttributeMap.AttributeType.Contains("$_")) {
              $AttributeMap.AttributeType["$_"]
            } else {
              $_
            }
          } else {
          
            # Enum handling
            
            $Type = $AttributeMap.AttributeType -as [Type]
            if ($Type -and $Type.BaseType.Name -eq "Enum") {
            
              if ($_.GetType() -eq [__ComObject]) {
                $_ = ConvertFromKSADLargeInteger $_
              } elseif ($_.GetType() -in [Int32], [Int64]) {
                $_ = ConvertFromKSADWrappedInteger $_
              }
            
              # Get the value(s) from the Enum. If the value does not exist in the Enum the original value will be returned.
              [Enum]::Parse([Type]$AttributeMap.AttributeType, $_)
              
            } elseif ($Type -eq [DateTime]) {
            
              # DateTime handling
            
              try { Get-Date $_ } catch { }
              if (-not $?) {
                # Attempt to cast it.
                Invoke-Expression "[$($Type.FullName)]$_"
              }
            } elseif ($Type) {
            
              # Arbitrary type handling
              
              if (-not ($_ -is $Type)) {
                [Convert]::ChangeType($_, $Type)
              }
            } else {
            
              # Conversion scripts
            
              $ConversionScript = Get-KSADAttributeConverter $AttributeMap.AttributeType
              if ($ConversionScript.Definition) {
                & $AttributeMap.AttributeType $_
              } elseif ($ConversionScript.SourcePath) {
                & $ConversionScript.SourcePath $_
              } else {
                Write-Warning "Attribute converter defined for $Name but no converter imported."
              }
            }
          }
        } else {
          switch -regex ($_) {
            '^(TRUE|FALSE)$' { [Convert]::ToBoolean($_); break }
            '^\d+\.\d+Z$'    { [DateTime]::ParseExact($_, "yyyyMMddHHmmss.0Z", $null); break }
            default          {
              if ($_ -is [DateTime]) {
                $_.ToLocalTime()
              } elseif ($_ -is [__ComObject] -and $Name -in 'uSNChanged', 'uSNCreated') {
                ConvertFromKSADLargeInteger $_
              } else {
                $_
              }
            }
          }
        }
      }
      $PSObject | Add-Member $Name -MemberType NoteProperty -Value $Value
    }

    if ($PSObject.userAccountControl) {
      # Property: AccountIsDisabled
      $PSObject | Add-Member "AccountIsDisabled" -MemberType ScriptProperty -Value { [Boolean]($this.userAccountControl -band [KScript.AD.UserAccountControl]::AccountDisable) }
      # Property: PasswordNeverExpires
      $PSObject | Add-Member "PasswordNeverExpires" -MemberType ScriptProperty -Value { [Boolean]($this.userAccountControl -band [KScript.AD.UserAccountControl]::DoNotExpirePassword) }
    }
    # Property: Identity - Identity based on the objectGUID
    if ($PSObject.objectGUID) {
      $PSObject | Add-Member "Identity" -MemberType NoteProperty -Value $PSObject.objectGUID
    }
    # Property: Path - Only applicable if the object does not have a distinguishedName
    if (-not $PSObject.distinguishedName -and $ObjectPath) {
      $PSObject | Add-Member "Path" -MemberType NoteProperty -Value $ObjectPath
    }
    # Property: Type - A simplified type property based on the objectClass attribute.
    if ($PSObject.objectclass) {
      $PSObject | Add-Member "Type" -MemberType NoteProperty -Value ($PSObject.objectclass[-1])
    } elseif ($ObjectType) {
      $PSObject | Add-Member "Type" -MemberType NoteProperty -Value $ObjectType
    }
    
    # User / computer specific properties
    if ($PSObject.Type -in 'User', 'Computer') {
      # Property: AccountIsExpired
      $PSObject | Add-Member "AccountIsExpired" -MemberType ScriptProperty -Value {
        if ($this.accountExpires -eq $null) {
          $false
        } else {
          $this.accountExpires -lt (Get-Date)
        }
      }
      # Property: AccountIsLockedOut
      $PSObject | Add-Member "AccountIsLockedOut" -MemberType ScriptProperty -Value {
        if ($this.GetAccountManagementPrincipal) {
          $this.GetAccountManagementPrincipal().IsAccountLockedOut()
        }
      }
    }
    
    return ($PSObject | Update-KSPropertyOrder)
  }
}