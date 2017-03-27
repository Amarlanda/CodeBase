function Expand-KSADLdapFilter {
  # .SYNOPSIS
  #   Expand any functions used in LDAP filters to the real values.
  # .DESCRIPTION
  #   Expand-KSADLdapFilter allows the use of several simplified values for LDAP filters.
  #
  #   Note: Replacement performed by Expand-KSADLdapFilter is case-sensitive. Function names must be entered exactly as described below.
  # 
  #   Supported functions:
  #
  #     %DATE(<Adjustment>)%                             Replaced with today's date, adjusted by the specified value if required.
  #     %GUID(<GUIDString>)%                             Replaced with a hexadecimal string representing the GUID.
  #     %LDAP_MATCHING_RULE_BIT_AND% or %LDAP_AND%       Replaced with 1.2.840.113556.1.4.803
  #     %LDAP_MATCHINE_RULE_BIT_OR% or %LDAP_OR%         Replaced with 1.2.840.113556.1.4.804
  #     %LDAP_MATCHINE_RULE_IN_CHAIN% or %LDAP_CHAIN%    Replaced with 1.2.840.113556.1.4.1941
  #
  #   Date supports the following arguments:
  #
  #     START
  #     END
  #     xHOUR
  #     xDAY
  #     xWEEK
  #     xMONTH
  #     xYEAR
  #
  #   x may be a positive or negative integer value.
  #
  #   The START and END arguments may be combined with any other DATE function as follows:
  #
  #     DATE(START, -2YEAR)
  #
  #   Expand-KSADLdapFilter can be used to convert friendly names for values to a name used by the directory. An enumeration must be defined (viewed using Get-KSADAttributeDefinition) to perform the conversion.
  # .PARAMETER LdapFilter
  #   The LDAP filter which should be expanded.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(whenCreated>=%DATE(START)%)"
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(accountExpires<=%DATE(-4WEEK)%)"
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(&(pwdLastSet<=%DATE(-2MONTH)%)(pwdLastSet>=%DATE(-1MONTH)%))"
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(&(whenCreated>=%DATE(START, -1MONTH)%)(whenCreated<=%DATE(END, -1MONTH)%))"
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(userAccountControl:%LDAP_AND%:=2)"
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(manager:%LDAP_CHAIN%:=CN=manager,DC=domain,DC=example)"
  # .EXAMPLE
  #   Expand-KSADLdapFilter "(objectGUID=%GUID(e6341ec5-5699-4069-8277-8cbb0c5cdc96)%)"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     01/10/2014 - Chris Dent - BugFix: Added missing support for not operator (!).
  #     12/08/2014 - Chris Dent - Fixed bug in regular expression used to rewrite values.
  #     25/07/2014 - Chris Dent - Added value conversion.
  #     30/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$LdapFilter
  )
  
  # DATE
  $RegEx = [RegEx]"\((?<AttributeName>[A-Za-z0-9\-]+)(?<Operator>=|<=|>=)%DATE(?:\((?<Arguments>[^\)]+)\))?%\)"
  $RegEx.Matches($LdapFilter) | ForEach-Object {
    # Date formatting is attribute specific.
    $AttributeName = $_.Groups['AttributeName'].Value
    $Operator = $_.Groups['Operator'].Value
    $Arguments = $_.Groups['Arguments'].Value
    
    $DateValue = Get-Date
    
    if ($Arguments) {
      switch -RegEx ($Arguments) {
        '^START(?:, *|$)'        { $DateValue = $DateValue.Date } 
        '^END(?:, *|$)'          { $DateValue = $DateValue.Date.AddDays(1).AddSeconds(-1) }
        '(?:^|, *)(-?\d+)HOUR$'  { $DateValue = $DateValue.AddHours([Int32]$matches[1]); break }
        '(?:^|, *)(-?\d+)DAY$'   { $DateValue = $DateValue.AddDays([Int32]$matches[1]); break }
        '(?:^|, *)(-?\d+)WEEK$'  { $DateValue = $DateValue.AddDays(([Int32]$matches[1] * 7)); break }
        '(?:^|, *)(-?\d+)MONTH$' { $DateValue = $DateValue.AddMonths([Int32]$matches[1]); break }
        '(?:^|, *)(-?\d+)YEAR$'  { $DateValue = $DateValue.AddYears([Int32]$matches[1]); break }
      }
    }
    
    $AttributeMap = Get-KSADAttributeMap $AttributeName
    switch ($AttributeMap.AttributeType) {
      'LargeIntegerDate' { $DateValue = (New-TimeSpan "01/01/1601" $DateValue).Ticks; break }
      default            { $DateValue = $DateValue.ToString('yyyyMMddHHmmss.0Z') }
    }
    
    $LdapFilter = $LdapFilter.Replace($_.Value, "($AttributeName$Operator$DateValue)")
  }

  # GUID
  if ($LdapFilter -match '%GUID\(([^\)]+)\)%') {
    $GUID = "\$((([GUID]$matches[1]).ToByteArray() | ConvertTo-KSString -Hexadecimal) -join '\')"
    $LdapFilter = $LdapFilter -creplace '%GUID\(([^\)]+)\)%', $GUID
  }
  
  # OID values
  $LdapFilter = $LdapFilter -creplace ':%(LDAP_MATCHING_RULE_BIT_AND|LDAP_AND)%:=', ':1.2.840.113556.1.4.803:='
  $LdapFilter = $LdapFilter -creplace ':%(LDAP_MATCHING_RULE_BIT_OR|LDAP_OR)%:=', ':1.2.840.113556.1.4.804:='
  $LdapFilter = $LdapFilter -creplace ':%(LDAP_MATCHING_RULE_IN_CHAIN|LDAP_CHAIN)%:=', ':1.2.840.113556.1.4.1941:='
  
  # Value conversion
  $RegEx = [RegEx]"\((?<NotOperator>!?)(?<AttributeName>[A-Za-z0-9\-]+)(?<Operator>(?::[0-9\.]+:)?=)(?<Value>[^\)]+)\)"
  $RegEx.Matches($LdapFilter) | ForEach-Object {
    $NotOperator = $_.Groups['NotOperator'].Value
    $AttributeName = $_.Groups['AttributeName'].Value
    $Operator = $_.Groups['Operator'].Value
    $Value = $_.Groups['Value'].Value
  
    $AttributeMap = Get-KSADAttributeMap $AttributeName
    if (($AttributeMap.AttributeType -as [Type]).BaseType -eq [Enum]) {
      $Value = [Enum]::Parse(($AttributeMap.AttributeType -as [Type]), $Value).value__
    }
    
    $LdapFilter = $LdapFilter.Replace($_.Value, "($NotOperator$AttributeName$Operator$Value)")
  }
  
  return $LdapFilter
}