function Get-KSModule {
  # .SYNOPSIS
  #   Get a list of available KScript.* modules from the local system.
  # .DESCRIPTION
  #   Get-KSModule retrieves a list of local module and compares to a list held on the path defined by Set-KSSourcePath.
  #
  #   Get-KSModule can be used in conjunction with Install-KSModule to install, update and reinstall modules.
  # .PARAMETER IncludeProcessAutomation
  #   By default Get-KSModule does not list modules tagged as created for ProcessAutomation. These modules can be included using this parameter.
  # .PARAMETER Name
  #   A module name beginning with "KScript.", such as KScript.AD. This value is used to apply a simple filter to the results of the search.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.Module.Description
  # .EXAMPLE
  #   Get-KSModule
  #
  #   Get a list of all available Indented.* modules.
  # .EXAMPLE
  #   Get-KSModule KScript.AD
  #
  #   Get a specific module by name.
  # .LINK
  #   http://www.indented.co.uk/indented-common/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #   Module: Indented.Common
  #
  #   (c) 2008-2014 Chris Dent.
  #
  #   Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, 
  #   provided that the above copyright notice and this permission notice appear in all copies.
  #
  #   THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED 
  #   WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR 
  #   CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF 
  #   CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.  
  #
  #   Change log:
  #     19/12/2014 - Chris Dent - Added filter to hide ProcessAutomation from normal usage.
  #     18/12/2014 - Chris Dent - Added ModuleType (based on XML description).
  #     10/07/2014 - Chris Dent - Fixed ServerVersion casting.
  #     04/07/2014 - Chris Dent - Modified to read settings using Get-KSSetting.
  #     25/06/2014 - Chris Dent - Modified module discovery process.
  #     20/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [String]$Name,
    
    [Switch]$IncludeProcessAutomation
  )
  
  $WhereStatementText = '$_'
  if ($Name) {
    $WhereStatementText = $WhereStatementText + ' -and $_.Name -eq $Name'
  }
  $WhereStatementText = $WhereStatementText + ' -and ($_.ModuleType -ne "ProcessAutomation" -or $IncludeProcessAutomation)'
  $WhereStatement = [ScriptBlock]::Create($WhereStatementText)
  
  $ModuleUpdatePath = Get-KSSetting KSModuleUpdatePath -ExpandValue
    
  $ServerModuleList = @{}
  if (Test-Path "$ModuleUpdatePath\modulelist.csv") {
    Import-Csv "$ModuleUpdatePath\modulelist.csv" | ForEach-Object {
      $ServerModuleList.Add($_.Name, $_)
    }
  }

  $ModuleList = @()
  
  $LocalModuleList = @{}
  $ModuleList += Get-Module KScript.* -ListAvailable |
    Select-Object `
      Name,
      @{n='LocalVersion';e={ $_.Version }},
      @{n='ModuleType';e={ ([XML]$_.Description).module.type }},
      @{n='Description';e={ if ($_.Description -match '^<module>') { ([XML]$_.Description).module.description } else { $_.Description } }} |
    ForEach-Object {
      $LocalModuleList.Add($_.Name, "")

      # Versions will not be correctly reported if the module has been updated and is listed as a RequiredModule.
      if (($_.LocalVersion -eq [Version]"0.0" -or -not $_.Description) -and $_.Path) {
        $ModuleManifest = Invoke-Expression (Get-Content $_.Path -Raw)
        $_.LocalVersion = [Version]$ModuleManifest['ModuleVersion']
        if ($ModuleManifest['Description'] -match '^<module>') {
          $DescriptionMetadata = [XML]$ModuleManifest['Description']
          $_.Description = $DescriptionMetadata.module.description
          $_.ModuleType = $DescriptionMetadata.module.type
        } else {
          $_.Description = $ModuleManifest['Description']
        }
      }
      if ($ServerModuleList.Contains($_.Name)) {
        $ServerVersion = [Version]($ServerModuleList[$_.Name].ServerVersion)
      } else {
        $ServerVersion = "Not available"
      }
      $_ | Add-Member ServerVersion -MemberType NoteProperty -Value $ServerVersion
  
      $_
    }
    
  $ModuleList += $ServerModuleList.Values |
    Where-Object { -not ($LocalModuleList.Contains($_.Name)) } |
    Select-Object *, @{n='LocalVersion';e={ "Not installed" }}
 
  $ModuleList | Select-Object Name, LocalVersion, ServerVersion, ModuleType, Description, Path | ForEach-Object {
    $_.PSObject.TypeNames.Add("KScript.Module.Description")
    
    $_
  } | Where-Object $WhereStatement
}