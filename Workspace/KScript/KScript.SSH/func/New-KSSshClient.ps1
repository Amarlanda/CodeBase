Function New-KSSshClient {
  # .SYNOPSIS
  #   Create a new SSH client using the specified ComputerName and credentials.
  # .DESCRIPTION
  #   Create an SSH client used to send SSH commands.
  # .PARAMETER ComputerName
  #   The name or IP address of the remote host.
  # .PARAMETER Credential
  #   The credentials which should be used for this connection.
  # .PARAMETER Port
  #   The TCP port used for SSH. By default TCP/22 is used.
  # .INPUTS
  #   System.String
  #   System.UInt16
  #   System.Management.Automation.PSCredential
  # .OUTPUTS
  #   Renci.SshNet.SshClient
  # .EXAMPLE
  #   New-KSSshClient -ComputerName SomeServer -Credential (Get-Credential)
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/10/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$ComputerName,
    
    [UInt16]$Port = 22,
    
    [PSCredential]$Credential
  )

  process {
    $NetworkCredential = $Credential.GetNetworkCredential()
  
    New-Object Renci.SshNet.SshClient($ComputerName, $Port, $NetworkCredential.Username, $NetworkCredential.Password)
  }
}