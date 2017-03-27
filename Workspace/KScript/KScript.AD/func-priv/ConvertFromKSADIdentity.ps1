function ConvertFromKSADIdentity {
  # .SYNOPSIS
  #   Convert a unique identity value into an appropriate LDAP filter.
  # .DESCRIPTION
  #   Internal use only.
  # .PARAMETER Identity
  #   An objectGUID, DistinguishedName or UserPrincipalName which can be used to uniquely identify an account across a forest.
  # .INPUTS
  #   System.Object
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   ConvertFromKSADIdentity "b7eaf79a-024d-4658-b3d9-bff29fa2c508"
  # .EXAMPLE
  #   ConvertFromKSADIdentity "CN=Test User,OU=somewhere,DC=domain,DC=example"
  # .EXAMPLE
  #   ConvertFromKSADIdentity "TestUser@domain.example"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     04/08/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Object]$Identity
  )
  
  if ($Identity -is [Guid] -or $Identity -match '^[a-f0-9]{8}-([a-f0-9]{4}-){3}[a-f0-9]{12}$') {
    $Identity = [Guid]$Identity
    return "(objectGUID=\$(($Identity.ToByteArray() | ConvertTo-KSString -Hexadecimal) -join '\'))"
  } elseif ($Identity -match '^CN=.+,((OU|CN)=.+,)*(DC=(.+)){1,}$') {
    return "(distinguishedName=$Identity)"
  } elseif ($Identity -match '^[^@]+@[A-Z0-9\-]+(\.[A-Z0-9\-]+)*$') {
    return "(userPrincipalName=$Identity)"
  } else {
    Write-Error "Invalid identity parameter, objectGUID or DistinguishedName are acceptable values." -Category InvalidArgument
  }
}