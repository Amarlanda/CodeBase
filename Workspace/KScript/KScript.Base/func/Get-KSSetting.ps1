function Get-KSSetting {
  # .SYNOPSIS
  #   Get global settings used by KScript modules.
  # .DESCRIPTION
  #   Get-KSGlobalSetting retrieves specific global settings such as mail server names, module source locations, etc.
  #
  #   A number of predefined setting names are used by KScript:
  #
  #     KSGlobalSettings            Local setting defining the path to any global settings file. Used by Get/Set-KSSetting.
  #     KSLogPath                   Local setting defining a default log folder. Used by NewLog (via NewLog).
  #     KSModuleAutoUpdate          Local boolean setting indicating whether or not auto-update is enabled. Used by Start-KSAutoUpdate.
  #     KSReportPath                Local setting defining a folder to store generated HTML reports (reports which are normally sent by mail).
  #     KSTranscriptLogPath         Local setting definint a folder to store transcript log files created using Write-KSLog.
  #     KSAdministratorsEmail       Global setting which holds a default e-mail address for administrators receiving debug information by e-mail. Shared.
  #     KSEventLogCodes             Global setting defining a path to assigned event log codes. Used by Write-Log (via NewLog).
  #     KSLogAgeLimit               Global setting defining the number of days to retain log files before archiving.
  #     KSLogArchiveAgeLimit        Global setting defining the number of days to retain log archive files before deleting.
  #     KSModuleUpdatePath          Global setting describing a path to KScript module repository. Used by Install-KSModule.
  #     KSTextResourcePath          Global setting describing a path to text resources (such as shared CSS and HTML elements). Used by Get-KSTextResource.
  #     KSUsersEmail                Global setting which holds a default e-mail address for users receiving e-mail notifications from scripts. Shared.
  #
  # .PARAMETER GlobalVariable
  #   Get settings which have been set to export into Global scope.
  # .PARAMETER Name
  #   Get a specific setting by name.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Base.Setting
  # .EXAMPLE
  #   Get-KSSetting
  #
  #   Return all settings.
  # .EXAMPLE
  #   Get-KSSetting -Name SmtpServer
  #
  #   Get the SMTP server setting.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/08/2014 - Chris Dent - Help section updated.
  #     10/07/2014 - Chris Dent - Fixed trailing null return when using LocalOnly.
  #     04/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [String]$Name,
    
    [Switch]$GlobalVariable,
    
    [Switch]$ExpandValue,
    
    [Switch]$LocalOnly
  )

  $FileName = "$psscriptroot\..\var\local-settings.xml"
  $XPathNavigator = New-KSXPathNavigator $FileName
  
  if ($Name -and $GlobalVariable) {  
    $XPathExpression = "/Settings/Item[Name='$Name' and ExportGlobalVariable='TRUE']"
  } elseif ($Name) {
    $XPathExpression = "/Settings/Item[Name='$Name']"
  } elseif ($GlobalVariable) {
    $XPathExpression = "/Settings/Item[ExportGlobalVariable='TRUE']"
  } else {
    $XPathExpression = "/Settings/Item"
  }

  $LocalSettings = $XPathNavigator.Select($XPathExpression) | ConvertFrom-KSXPathNode -ToObject | ForEach-Object {
    $_.PSObject.TypeNames.Add("KScript.Base.Setting")
      
    $_ | Add-Member Source -MemberType NoteProperty -Value "Local" -PassThru
  }

  # KSGlobalSettings can only be defined locally.
  if ($Name -ne 'KSGlobalSettings' -and -not $LocalOnly) {
    $KSGlobalSettings = Get-KSSetting -Name KSGlobalSettings -ExpandValue

    if ($KSGlobalSettings -and (Test-Path $KSGlobalSettings)) {
      $XPathNavigator = New-KSXPathNavigator $KSGlobalSettings

      $GlobalSettings = $XPathNavigator.Select($XPathExpression) |
        ConvertFrom-KSXPathNode -ToObject |
        Where-Object { $_.Name -notin ($LocalSettings | Select-Object -ExpandProperty Name) } |
        ForEach-Object {
          $_.PSObject.TypeNames.Add("KScript.Base.Setting")
              
          $_ | Add-Member Source -MemberType NoteProperty -Value "Global" -PassThru
        }
    }
  }
  
  $Settings = [Array]$LocalSettings + [Array]$GlobalSettings | Where-Object { $_ }
  if ($ExpandValue) {
    return $Settings | Select-Object -ExpandProperty Value
  } else {
    return $Settings
  }
}