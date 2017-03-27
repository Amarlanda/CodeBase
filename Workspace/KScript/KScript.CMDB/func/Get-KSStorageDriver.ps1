function Get-KSStorageDriver {
  # .SYNOPSIS
  #   Get all storage drivers.
  # .DESCRIPTION
  #   Get-KSStorageDriver attempts to get details of all storage drivers installed or present on the computer.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER Credential
  #   By default current user is used, alternate credentials may be specified if required.
  # .INPUTS
  #   System.Management.Automation.PSCredential
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   Get-KSStorageDriver
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/01/2015 - Chris Dent - Changed Get-WmiObject to Get-CimInstance.
  #     10/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$ComputerName = $env:ComputerName,

    [PSCredential]$Credential
  )

  begin {
    $CimSessionOptions = New-CimSessionOption -Protocol Dcom -Culture (Get-Culture) -UICulture (Get-Culture)
  }
  
  process {
    $CimSession = New-CimSession @psboundparameters -SessionOption $CimSessionOptions

    if ($?) {
      $CimParams = @{
        CimSession          = $CimSession
        OperationTimeoutSec = 30
      }

      $SystemDirectory = Get-CimInstance Win32_OperatingSystem @CimParams | Select-Object -ExpandProperty SystemDirectory
      if (-not $?) {
        $SystemDirectory = "C:\Windows"
      }
      $DriverDirectory = "$SystemDirectory\drivers\"
      # Escape \, reserved character in WMI filters.
      $DataFilePath = $DriverDirectory -replace '\\', '\\'
    
      # CIM_DataFile
      'storport.sys', 'msdsm.sys', 'mpio.sys' | ForEach-Object {
        Get-CimInstance -ClassName CIM_DataFile -Filter "Name='$DataFilePath$_'" @CimParams |
          Select-Object `
            @{n='Name';e={ $_.FileName }},
            @{n='Version';e={ [Version]$_.Version }},
            @{n='PathName';e={ $_.Name }}
      }
    }
  }
}