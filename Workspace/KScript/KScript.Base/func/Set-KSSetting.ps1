function Set-KSSetting {
  # .SYNOPSIS
  #   Set a setting for KScript modules.
  # .DESCRIPTION
  #   Set-KSSetting adds or changes specific global settings such as mail server names, module source locations, etc.
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
  # .PARAMETER Name
  #   The setting name to add or change.
  # .PARAMETER Value
  #   The value to set for the variable.
  # .PARAMETER GlobalSetting
  #   Attempt to add a setting to the global settings file using the path published in KSGlobalSettings.
  # .PARAMETER GlobalVariable
  #   Get settings which have been set to export into Global scope.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Base.Setting
  # .EXAMPLE
  #   Set-KSSetting -Name SmtpServer -Value mail.domain.example
  #
  #   Set the SmtpServer setting to mail.domain.example.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/08/2014 - Chris Dent - Help section updated.
  #     08/07/2014 - Chris Dent - Added switch to allow changes to KSGlobalSettings file.
  #     04/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidatePattern('[A-Z0-9_]+')]
    [ValidateNotNullOrEmpty()]
    [String]$Name,
    
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [String]$Value,
    
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Alias('ExportGlobalVariable')]
    [Boolean]$GlobalVariable,
    
    [Switch]$GlobalSetting,
    
    [Switch]$PassThru
  )

  begin {
    if ($GlobalSetting) {
      $FileName = Get-KSSetting KSGlobalSettings -ExpandValue
      if (-not (Test-Path $FileName -PathType Leaf)) {
        $ErrorRecord = New-Object Management.Automation.ErrorRecord(
          (New-Object Exception "Unable to access global settings file ($FileName)."),
          "ResourceUnavailable",
          [Management.Automation.ErrorCategory]::ResourceUnavailable,
          $pscmdlet)
        $pscmdlet.ThrowTerminatingError($ErrorRecord)
      }
    } else {
      $FileName = "$psscriptroot\..\var\local-settings.xml"
    }
    
    $XPathNavigator = New-KSXPathNavigator $FileName -Mode Write
    
    if (($XPathNavigator.Select("/Settings") | Measure-Object).Count -eq 0) {
      $XPathNavigator.AppendChild("<Settings />")
    }
  }
  
  process {
    $XPathNode = $XPathNavigator.Select("/Settings/Item[translate(Name, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($Name.ToLower())']")

    if (($XPathNode | Measure-Object).Count -gt 0) {
      $Setting = $XPathNode | ConvertFrom-KSXPathNode
      
      if ($psboundparameters.ContainsKey("Value") -and $Setting.Value -ne $Value) {
        $XPathNode.Select("./Value").SetValue($Value)
      }
      
      $Setting.PSObject.Properties['ExportGlobalVariable']
      
      if ($XPathNode.Select("./ExportGlobalVariable")) {
        if ($psboundparameters.ContainsKey("GlobalVariable") -and $GlobalVariable -ne $Setting.ExportGlobalVariable) {
          $XPathNode.Select("./ExportGlobalVariable").SetValue([Convert]::ToString($GlobalVariable).ToUpper())
        }
      } else {
        $XPathNode.AppendChild("<ExportGlobalVariable>$([Convert]::ToString($GlobalVariable).ToUpper())</ExportGlobalVariable>")
      }
    } else {
      $XPathNavigator.Select("/Settings").AppendChild("<Item><Name>$Name</Name><Value>$Value</Value><ExportGlobalVariable>$([Convert]::ToString($GlobalVariable).ToUpper())</ExportGlobalVariable></Item>")
    }
    
    $XPathNavigator.UnderlyingObject.Save($FileName)

    if ($PassThru) {
      Get-KSSetting -Name $Name
    }
  }
}