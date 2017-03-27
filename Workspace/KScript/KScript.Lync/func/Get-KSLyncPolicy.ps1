function Get-KSLyncPolicy {
  # .SYNOPSIS
  #   Get policies defined in an XML file.
  # .DESCRIPTION
  #   Get-KSLyncPolicy reads an XML file describing policies (sets of commands) to be applied to users based on certain criteria.
  #
  #   KS Lync Policies support the following filtering mechanisms:
  #
  #     * LdapFilter
  #     * SearchRoot
  #     * PatternMatch
  #
  #   Pattern matching is the least efficient method as it cannot filter the result set. Pattern matches are applied to an object returned by Get-CsAdUser, therefore the property name must be one returned by Get-CsAdUser.
  #
  #   Policies are applied to the users meeting all of the filtering requirements.
  #
  #   The XML file uses the following format:
  # 
  #   <Policies>
  #     <Policy>
  #       <Name>Policy Name</Name>
  #       <Filters>
  #         <Filter>
  #           <Type>LdapFilter or SearchRoot</Type>
  #           <Value><![CDATA[ Value ]]></Value>
  #         </Filter>
  #         <Filter>
  #           <Type>PatternMatch</Type>
  #           <Property>PropertyName</Property>
  #           <Pattern><![CDATA[ RegularExpression ]]></Pattern>
  #         </Filter>
  #       </Filters>
  #       <Commands>
  #         <Command>
  #           <Name>LyncCommand</Name>
  #           <Parameters>
  #             <Parameter>
  #               <Name>ParameterName</Name>
  #               <Value>ParameterValue</Value>
  #             </Parameter>
  #           </Parameters>
  #         </Command>
  #       </Commands>
  #     </Policy>
  #   </Policies>
  #
  #   If the ParameterValue is set to True, false or null the value is converted to an appropriate value, otherwise the value is treated as a string.
  #
  #   Multiple parameters may be defined for any given command. Multiple commands may be defined for any policy.
  #
  #   Policies are applied in the order they are listed in the XML file. If policies conflict the last policy wins (each will be applied in sequence).
  # .PARAMETER Name
  #   The name of a specific policy.
  # .PARAMETER PolicyDefinitionFile
  #   An XML file used to define policy sets.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Lync.Policy
  # .EXAMPLE
  #   Get-KSLyncPolicy
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     13/08/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [String]$Name,
    
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [String]$PolicyDefinitionFile = "$psscriptroot\..\var\policy-commands.xml"
  )
  
  $XPathNavigator = New-KSXPathNavigator $PolicyDefinitionFile
  
  if ($Name) {
    $XPathExpression = "/Policies/Policy[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']"
  } else {
    $XPathExpression = "/Policies/Policy"
  }
  
  $XPathNavigator.Select($XPathExpression) | ForEach-Object {
    $Policy = $_ | ConvertFrom-KSXPathNode -ToObject

    #
    # Filter sets
    #
    
    $Policy.Filters = $_.Select("./Filters/Filter") | ForEach-Object {
      $_ | ConvertFrom-KSXPathNode -ToObject
    }
    
    #
    # Command sets
    #
      
    $Policy.Commands = $_.Select("./Commands/Command") | ForEach-Object {
      $Command = $_.Select('./Name').Value
      
      $LyncCommand = Get-Command $Command -Module Lync
      if (-not $LyncCommand) {
        Write-Error "Invalid command specified ($Command). Ignoring command."
      } else {
        $Parameters = $_.Select('./Parameters/Parameter') | ForEach-Object {
          $ParameterName = $_.Select('./Name').Value
          if (-not $LyncCommand.Parameters[$ParameterName]) {
            Write-Error "Invalid parameter specified ($Command : $ParameterName)"
            # Prevent this command being used.
            $Command = $null
          } else {
            $ParameterValue = $_.Select('./Value').Value
            # Convert boolean and null values
            if ($ParameterValue -match '^(true|false)$') {
              $ParameterValue = "`$$((Get-Variable $ParameterValue).Value)"
            } elseif ($ParameterValue -match '^null$') {
              $ParameterValue = "`$null"
            } else {
              $ParameterValue = """$ParameterValue"""
            }
                
            "-$ParameterName $ParameterValue"
          }
        }

        # Assemble the command. Note: The Identity argument variables are hard-coded here.
        if ($Command) {
          "$Command -Identity `$CsUser.Identity $Parameters"
        }
      }
    }
    
    $Policy.PSObject.TypeNames.Add("KScript.Lync.Policy")
    
    $Policy
  }
}