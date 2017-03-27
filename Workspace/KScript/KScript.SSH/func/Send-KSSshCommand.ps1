function Send-KSSshCommand {
  # .SYNOPSIS
  #   Send an SSH command to an SSH client.
  # .DESCRIPTION
  #   Send an SSH command, or a set of of SSH commands to an SSH client and get the command output.
  # .PARAMETER Command
  #   A list of commands to execute on the remote host.
  # .PARAMETER SshClient
  #   An SSH client created using New-KSSshClient.
  # .INPUTS
  #   Renci.SshNet.SshClient
  #   System.String
  # .OUTPUTS
  #   System.String[]
  # .EXAMPLE
  #   Send-KSSshCommand "ls" -SshClient $SshClient
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     03/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipeline = $true)]
    [String[]]$Command,

    [Parameter(Mandatory = $true)]
    [Renci.SshNet.SshClient]$SshClient
  )

  process {
    $SshClient.Connect()
    $Command | ForEach-Object {
      $SshClient.RunCommand($_) | Select-Object -ExpandProperty Result
    }
    $SshClient.Disconnect()
  }
}