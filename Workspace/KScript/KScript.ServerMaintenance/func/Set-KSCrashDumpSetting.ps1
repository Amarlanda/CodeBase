function Set-KSCrashDumpSetting {
  # .SYNOPSIS
  #   Set the crash dump setting on the specified host.
  # .DESCRIPTION
  #   Set-KSCrashDumpSetting using the WMI registry provider to update the crash dump setting. Once set, the host must be rebooted to apply the setting.
  # .PARAMETER ComputerName
  #   The name of the computer to execute this action on.
  # .PARAMETER Credential
  #   By default this command executes with the rights of the caller. Alternate credentials may be specified if required.
  # .PARAMETER NewCrashDumpSetting
  #   The crash dump value to set. Possible values are:
  #
  #     Disabled
  #     CrashDump           Entire memory contents.
  #     KernelMemoryDump    Kernel-mode read / write pages only.
  #     SmallMemoryDump     Stop code, parameters and list of loaded devices drivers.
  #
  # .EXAMPLE
  #   Set-KSCrashDumpSetting -NewCrashDumpSetting KernelMemoryDump -ComputerName SomeComputer
  # .EXAMPLE
  #   Get-Content ServerList.txt | Set-KSCrashDumpSetting -NewCrashDumpSetting KernelMemoryDump
  # .LINKS
  #   http://blogs.technet.com/b/askperf/archive/2008/01/08/understanding-crash-dump-files.aspx
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/11/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [KScript.Server.CrashDump]$NewCrashDumpSetting,
  
    [Parameter(ValueFromPipelineByPropertyName = $true, ValueFromPipeline = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$ComputerName = $env:ComputerName,
    
    [PSCredential]$Credential
  )
  
  begin {
    $Params = @{}
    if ($Credential) {
      $Params.Add("Credential", $Credential)
    }
  }
  
  process {
    if ((Get-KSCrashDumpSetting @Params -ComputerName $ComputerName) -eq $NewCrashDumpSetting) {
      Write-Warning "Set-KSCrashDumpSetting: The requested CrashDumpEnabled value is already set. No changes have been made."
    } else {
      $WmiResponse = Invoke-WmiMethod SetDWordValue -Class StdRegProv -Namespace root/Default -ComputerName $ComputerName -ArgumentList `
        [KScript.Wmi.Registry.Hive]::HKLM,
        "System\CurrentControlSet\Control\CrashControl",
        "CrashDumpEnabled",
        [Int32]$NewCrashDumpSetting
      
      if ($WmiResponse['ReturnValue'] -eq 0) {
        Write-Verbose "Set-KSCrashDumpSetting: Update CrashDumpEnabled value"
      } else {
        
      }
    }
  }
}