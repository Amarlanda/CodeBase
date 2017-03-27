function Get-KSInstalledSoftware {
  # .SYNOPSIS
  #   Get all installed from the Uninstall keys in the registry.
  # .DESCRIPTION
  #   Read a list of installed software from each Uninstall key.
  #
  #   This method provides an alternative to using the WMI class Win32_Product which causes an msi reconfiguration action.
  #
  #   This CmdLet assumes the user is authenticated.
  # .PARAMETER ComputerName
  #   The computer to execute against. By default the local computer is used.
  # .PARAMETER StartRemoteRegistry
  #   The script should attempt to start the remote registry service if it is not already running. This parameter will only take effect if the service is not disabled.
  # .PARAMETER IncludeLoadedUserHives
  #   Some software packages, such as DropBox install into a users profile rather than into shared areas. Get-InstalledSoftware can increase the search to include each loaded user hive.
  #
  #   If a registry hive is not loaded it cannot be searched, this is a limitation of this search style.
  # .PARAMETER IncludeBlankNames
  #   By default Get-InstalledSoftware will suppress the display of entries with minimal information. If no DisplayName is set it will be hidden from view. This behaviour may be changed using this parameter.
  # .PARAMETER DebugConnection
  #   By default error messages are suppressed. A large number of errors may be returned by a single device because of the granular nature of registry permissions. This parameter allows the displays of all caught exceptions for debugging purposes.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.CMDB.SoftwareItem
  # .EXAMPLE
  #   Get-InstalledSoftware
  #
  #   Get the list of installed applications from the local computer.
  # .EXAMPLE
  #   Get-InstalledSoftware -IncludeLoadedUserHives
  #
  #   Get the list of installed applications from the local computer, including each loaded user hive.
  # .EXAMPLE
  #   Get-InstalledSoftware -ComputerName None -DebugConnection
  #
  #   Display all error messages thrown when attempting to audit the specified computer.
  # .EXAMPLE
  #   Get-InstalledSoftware -IncludeBlankNames
  #
  #   Display all results, including those with very limited information.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     08/12/2014 - Chris Dent - Updated error handling (allowed code to return errors to caller).
  #     23/10/2014 - Chris Dent - Removed ComputerName property (compatibility with KScript.CMDB). Fixed InstallDate reference.
  #     30/07/2014 - Mark Cini - Adjusted code to support PowerShell version 2.
  #     17/07/2014 - Chris Dent - Forked from original (http://www.indented.co.uk/2014/01/15/get-installedsoftware/).
  
  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
    [String]$ComputerName = $env:ComputerName,

    [Switch]$StartRemoteRegistry,

    [Switch]$IncludeLoadedUserHives,
    
    [Switch]$IncludeBlankNames
  )

  process {

    # If the remote registry service is stopped before this script runs it will be stopped again afterwards.
    if ($StartRemoteRegistry) {
      $ShouldStop = $false
      $Service = Get-WmiObject Win32_Service -Filter "Name='RemoteRegistry'" -Computer $ComputerName
      If ($Service.State -eq "Stopped" -And $Service.StartMode -ne "Disabled") {
        $ShouldStop = $true
        $Service.StartService() | Out-Null
      }
    }
    
    # Create an array to hold open base keys. The Uninstall key should be relative and fixed from here.
    $BaseKeys = @()
    
    if ($IncludeLoadedUserHives) {
      $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("Users", $ComputerName)
      
      if ($? -and $BaseKey) {
        $BaseKey.GetSubKeyNames() | ForEach-Object {
          $SubKeyName = $_
          $BaseKeys += $BaseKey.OpenSubKey($SubKeyName)
        }
      }
    }

    # Connect to the base key
    $BaseKey = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $ComputerName)
    if ($? -and $BaseKey) {
      $BaseKeys += $BaseKey
    }
    
    # Begin reading package information from the registry
    $Packages = @{}
    $BaseKeys | Where-Object { $_ } | ForEach-Object {
      $BaseKey = $_

      # Uninstall keys relative to each base.
      "Software\Microsoft\Windows\CurrentVersion\Uninstall", "Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" | ForEach-Object {
        $UninstallKeyString = $_
        $UninstallKey = $BaseKey.OpenSubKey($UninstallKeyString)
        if ($? -and $UninstallKey) {
          $UninstallKey.GetSubKeyNames() | ForEach-Object {
            $SubKeyName = $_
            $UninstallKey.OpenSubKey($_) | ForEach-Object {
              # Create a new record for this package
              if ($Packages.Contains($SubKeyName)) {
                [Array]$Packages[$SubKeyName].RegistryKeys += "$($BaseKey.ToString())\$UninstallKeyString"
              } else {
                $DateString = $_.GetValue("InstallDate"); [Nullable``1[[DateTime]]]$InstallDate = Get-Date; [String]$InstallDateString = ""
                if ($DateString) {
                  if ([DateTime]::TryParseExact($DateString, "yyyyMMdd", [Globalization.CultureInfo]::CurrentCulture, "None", [Ref]$InstallDate)) {
                    $InstallDateString = $InstallDate
                  } else {
                    $InstallDateString = $DateString
                  }
                }
                
                $Package = New-Object PsObject -Property @{
                  Name            = $_.GetValue("DisplayName");
                  DisplayVersion  = $_.GetValue("DisplayVersion");
                  InstallDate     = $InstallDateString;
                  InstallLocation = $_.GetValue("InstallLocation");
                  HelpLink        = $_.GetValue("HelpLink");
                  Publisher       = $_.GetValue("Publisher");
                  UninstallString = $_.GetValue("UninstallString");
                  URLInfoAbout    = $_.GetValue("URLInfoAbout");
                  KeyName         = $SubKeyName;
                  RegistryKeys    = "$($BaseKey.ToString())\$UninstallKeyString";
                  InstalledAs     = "";
                } | Select Name, DisplayVersion, InstallDate, InstallLocation, HelpLink, Publisher, UninstallString, URLInfoAbout, KeyName, RegistryKeys, InstalledAs 

                $Packages.Add($SubKeyName, $Package)
              }
            }
          }
        }
      }
    }

    # Attempt to resolve SID strings to something a bit more friendly. This method is a bit limited.
    $InstalledAs = @{}
    $Packages.Values |
      ForEach-Object { $_.RegistryKeys } |
      Select-Object -Unique |
      ForEach-Object {
        if ($_ -match '^HKEY_LOCAL_MACHINE') {
          if ($_ -match 'Wow6432Node') {
            $InstalledAs.Add($_, "LocalMachine\64Bit")
          } else {
            $InstalledAs.Add($_, "LocalMachine\32Bit")
          }
        } elseif ($_ -match '^HKEY_USERS\\(?<SID>[^\\]+)') {
          $NTAccount = (New-Object Security.Principal.SecurityIdentifier $matches.SID).Translate([Security.Principal.NTAccount]).Value
          if ($NTAccount) {
            $InstalledAs.Add($_, $NTAccount)
          } else {
            $InstalledAs.Add($_, $matches.SID)
          }
        }
      }
    $Packages.Keys | ForEach-Object {
      $Packages[$_].InstalledAs = ($Packages[$_].RegistryKeys | ForEach-Object { $InstalledAs[$_] })
    }
    
    # Stop the remote registry service if required
    if ($StartRemoteRegistry -and $ShouldStop) {
      $Service.StopService() | Out-Null
    }

    # Output filtering
    if ($IncludeBlankNames) {
      return $Packages.Values
    } else {
      return ($Packages.Values | Where-Object { $_.Name })
    }
  }
}