function Update-KSModuleRelease {
  # .SYNOPSIS
  #   Update a release of an existing module.
  # .DESCRIPTION
  #   Automates the process of updating an releasing modules.
  # .PARAMETER Name
  #   The name of the module within the TFS workspace.
  # .PARAMETER TestPath
  #   The path used to test modules.
  # .PARAMETER LiveRelease
  #   Update the distributed release of this module.
  # .PARAMETER MajorRelease
  #   Increment the major version number of this module.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     31/10/2014 - Chris Dent - Re-added New-KSModuleDocument call.
  #     04/08/2014 - Chris Dent - Only update TFS if IncrementVersion is set (testing complete).
  #     22/07/2014 - Chris Dent - Overhauled. Added support for TFS.
  #     18/07/2014 - Chris Dent - Added a date field to the module information file. Added an algorithm to generate release notes.
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
    [String]$Name,
  
    [Switch]$IncrementVersion,
    
    [Switch]$Major
  )

  begin {
    Update-TfsWorkspaceItems -Force | Out-Null
  }
  
  process {
    if ($Name -and (Test-Path "$Script:WorkspacePath\KScript\$Name" -PathType Container)) {
      $CandidateModule = Get-Item "$Script:WorkspacePath\KScript\$Name"

      New-KSModuleDocument $Name
      New-KSModuleSPPage $Name

      if ($IncrementVersion) {
        # Version numbering
        $ModuleManifest = Get-KSModuleManifest -Name $Name
        $Version = [Version]($ModuleManifest["ModuleVersion"])
        if ($Major) {
          $Version = "$($Version.Major + 1).0"
        } else {
          $Version = "$($Version.Major).$($Version.Minor + 1)"
        }
        Update-KSModuleManifest $Name -Property ModuleVersion -Value $Version
        
        # Add new items to TFS
        Compare-TfsProjectItems -ProjectName KScript | ForEach-Object {
          if ($_.Status -eq 'Not added to project') {
            # Items are added to appropriate projects based on FullName
            Add-TfsItem -FileName $_.LocalItem
          }
        }
        
        # Update the version of the module on the file server
        robocopy $CandidateModule.FullName "$Script:PublishToPath/$($CandidateModule.Name)" /S /PURGE
      }
      
      # Update test release
      
      $ReleaseTestPath = ($env:PSModulePath -split ';')[0]
      robocopy $CandidateModule.FullName "$ReleaseTestPath\$($CandidateModule.Name)" /S /PURGE
    }
  }
  
  end {
    # Regenerate the version control file, modulelist.csv, in PublishToPath
    $OldModuleList = @{}
    Import-Csv "$Script:WorkspacePath\KScript\modulelist.csv" | ForEach-Object {
      $OldModuleList.Add($_.Name, $_)
    }
    
    Get-ChildItem $Script:WorkspacePath\KScript\KScript.* -Directory | ForEach-Object {
      if (Test-Path "$($_.FullName)\$($_.Name).psd1") {
        $ModuleManifest = Get-KSModuleManifest $_.Name
      
        $ModuleInformation = New-Object PsObject -Property ([Ordered]@{
          Name          = $_.Name
          ServerVersion = $ModuleManifest["ModuleVersion"]
          Description   = $ModuleManifest["Description"]
          LastUpdate    = (Get-Date)
          ModuleType    = ""
        })
        if ($OldModuleList.Contains($_.Name)) {
          if ([Version]$ModuleInformation.ServerVersion -le [Version]$OldModuleList[$_.Name].ServerVersion) {
            $ModuleInformation.LastUpdate = $OldModuleList[$_.Name].LastUpdate
          }
        }
        
        $ModuleInformation
      }
    } | Export-Csv "$Script:WorkspacePath\KScript\modulelist.csv" -NoTypeInformation
    
    Import-Csv "$Script:WorkspacePath\KScript\modulelist.csv" | Where-Object { $_.ServerVersion -ge [Version]"1.0" } | Export-Csv "$Script:PublishToPath\modulelist.csv" -NoTypeInformation
    
    if ($IncrementVersion) {
      # Commit this change-set.
      Update-TfsItem -ProjectName KScript
    }
  }
}