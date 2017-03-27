function Get-KSADDhcpServer {
  # .SYNOPSIS
  #   Get authorised DHCP servers from Active Directory.
  # .DESCRIPTION
  #   Get-KSADDhcpServer gets authorised DHCP servers from the configuration naming context.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified serverless binding is used (site-aware DC locator process). ComputerName is mandatory when executing a query against a remote forest.
  # .PARAMETER Credential
  #   Specifies a user account that has permission to perform this action. The default is the current user. Get-Credential can be used to create a PSCredential object for this parameter.
  # .PARAMETER Name
  #   The name of the DHCP server to find.
  # .PARAMETER SizeLimit
  #   The maximum number of results to be returned by the search. If SizeLimit is set, Paging is disabled. SizeLimit cannot be set higher than 1000. Setting SizeLimit to 0 returns all results.
  # .INPUTS
  #   System.String
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   KScript.AD.ExchangeServer
  # .EXAMPLE
  #   Get-KSADDhcpServer
  # .EXAMPLE
  #   Get-KSADDhcpServer -ComputerName RemoteServer
  # .EXAMPLE
  #   Get-KSADDhcpServer -Name "uk*"
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     21/11/2014 - Chris Dent - First release
  
  [CmdLetBinding()]
  param(
    [String]$Name,
    
    [ValidateRange(0, 1000)]
    [Int32]$SizeLimit = 100,
    
    [String]$ComputerName,
    
    [PSCredential]$Credential
  )

  $Params = @{}
  $psboundparameters.Keys |
    Where-Object { $_ -in (Get-KSCommandParameters Get-KSADRootDSE -ParameterNamesOnly) } |
    ForEach-Object {
      $Params.Add($_, $psboundparameters[$_])
    }
  $RootDSE = Get-KSADRootDSE @Params
  
  $Params = @{}
  $Params.Add("SearchRoot", $RootDSE.configurationNamingContext)
  $psboundparameters.Keys |
    Where-Object { $_ -in (Get-KSCommandParameters Get-KSADObject -ParameterNamesOnly) } |
    ForEach-Object {
      $Params.Add($_, $psboundparameters[$_])
    }

  $LdapFilter = "(&(objectClass=dhcpClass)(!name=DhcpRoot)(DhcpServers=*))"
  if ($Name) {
    $LdapFilter = "(&(|(dhcpServers=*`$s$($Name.ToLower()))(dhcpServers=*`$s$($Name.ToUpper())))(objectClass=dhcpClass)(!name=DhcpRoot)(DhcpServers=*))"
  }
  $Params.Add("LdapFilter", $LdapFilter)
  $Params.Add("Properties", @("DhcpServers"))

  Get-KSADObject @Params | ForEach-Object {
    if ($_.DhcpServers -match '.*i(?<IPAddress>(?:[0-9]{1,3}\.){3}[0-9]{1,3})\$.+\$s(?<DhcpServerName>[^$]+)\$') {
      $DhcpServer = New-Object PSObject -Property ([Ordered]@{
        ComputerName = $matches['DhcpServerName']
        IPAddress    = $matches['IPAddress']
      })

      $DhcpServer.PSObject.TypeNames.Add("KScript.AD.DhcpServer")
    
      $DhcpServer
    }
  }
}