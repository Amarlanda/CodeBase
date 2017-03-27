function Get-KSLastLogon {
  # .SYNOPSIS
  #   Get the last modified date of ntuser.dat for each user profile.
  # .DESCRIPTION
  #   Get-KSLastLogon attempts to estimate the last logon time for each user on a machine using the last write time of the ntuser.dat file (HKEY_CURRENT_USER registry hive). Returns $null for object properties which are not available.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.LastLogon
  # .EXAPMLE
  #   Get-KSLastLogon
  # .EXAMPLE
  #   "Computer1", "Computer2" | Get-KSLastLogon
  # .EXAMPLE
  #   Get-KSLastLogon -ComputerName SomeComputer
  # .EXAMPLE
  #   Get-KSLastLogon | Export-KSExcelWorksheet -FileName SomeWorksheet.xlsx
  # .EXAMPLE
  #   Get-Content SomeFile.txt | Get-KSLastLogon | Export-KSExcelWorksheet -FileName SomeWorksheet.xlsx
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/11/2014 - Chris Dent - Integrated into *-Asset.
  #     10/10/2014 - Chris Dent - Added UUID for CMDB database support.
  #     30/07/2014 - Mark Cini - Adjusted code to support PowerShell version 2. Implemented error handling for unresolvable SIDs, missing profile path settings and NTUser.dat files.
  #     29/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [String]$ComputerName = (hostname)
  )

  process {
    [Microsoft.Win32.RegistryHive]$Hive = "LocalMachine"
    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($Hive, $ComputerName)
    
    if ($BaseKey) {
      $ProfileList = $BaseKey.OpenSubKey("Software\Microsoft\Windows NT\CurrentVersion\ProfileList")
      $ProfileList.GetSubKeyNames() | ForEach-Object {
        $SubKey = $ProfileList.OpenSubKey($_)
      
        $ProfilePath = $SubKey.GetValue("ProfileImagePath")
        $RemoteProfilePath = "\\$ComputerName" + ($ProfilePath -replace '([A-Z]):\\(.+)', '\$1$\$2')
    
        try {
          $User = (New-Object Security.Principal.SecurityIdentifier($_)).Translate([Security.Principal.NTAccount])
        } catch [Exception] {
          $User = $null
        }
    
        if ($ProfilePath) {
          $NTUserDAT = "$RemoteProfilePath\ntuser.dat"
          if (Test-Path $NTUserDAT) {
            $LastWriteTime = (Get-Item $NTUserDAT -Force).LastWriteTime
          } else {
            $LastWriteTime = $null
          }
        } else {
          $ProfilePath = $null
          $LastWriteTime = $null
        }
        
        New-Object PSObject -Property @{
          User         = $User
          Sid          = $_
          ProfilePath  = $ProfilePath
          LastModified = $LastWriteTime
        } | Select User, Sid, ProfilePath, LastModified
      }
    }
  }
}