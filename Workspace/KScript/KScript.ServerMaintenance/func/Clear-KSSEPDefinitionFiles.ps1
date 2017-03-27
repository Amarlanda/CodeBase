function Clear-KSSEPDefinitionFiles {
  # .SYNOPSIS
  #   Clear old SEP definitions from the All Users profile.
  # .DESCRIPTION
  #   Remove folders associated with old versions of SEP.
  # .PARAMETER ComputerName
  #   The name of the computer to clear.
  # .PARAMETER Force
  #   Suppress confirmation diaglog.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.SEPVersion
  # .EXAMPLE
  #   Clear-KSSEPDefinitionFiles ukwatweb69
  #
  #   View and remove old SEP definition files from ukwatweb69.
  # .EXAMPLE
  #   Clear-KSSEPDefinitionFiles -ComputerName ukvmssrv143 -WhatIf
  #
  #   Look only, don't attempt to remove files.
  # .EXAMPLE
  #   Clear-KSSEPDefinitionFiles -ComputerName ukvmswts001 -Force
  #
  #   Skip confirmation diaglog.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     03/11/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [ValidateNotNullOrEmpty()]
    [String]$ComputerName = $env:ComputerName,
    
    [Switch]$Force
  )

  if (Test-Path "\\$Computername\c$\Users") {
    $DefinitionFolder = "\\$Computername\c$\Users\All Users\Symantec\Symantec Endpoint Protection"
  } elseif (Test-Path "\\$ComputerName\c$\Documents and Settings") {
    $DefinitionFolder = "\\$ComputerName\c$\Documents and Settings\All Users\Application Data\Symantec\Symantec Endpoint Protection"
  }
  
  if ($DefinitionFolder -and (Test-Path $DefinitionFolder)) {
    # Get the versions of SEP. Ignore empty folders or folders we cannot access.
    $SEPVersions = Get-ChildItem $DefinitionFolder -Directory |
      Where-Object { $_.Name -match '^(\d+\.){4}\d+' } |
      Sort-Object { [Version]($_.Name -replace '\.\d+$') } -Descending |
      Select-Object `
        @{n='ComputerName';e={ $ComputerName }},
        @{n='SEPVersion';e={ [Version]($_.Name -replace '\.\d+$') }},
        @{n='Size';e={ [Math]::Round(((Get-ChildItem $_.FullName -Recurse -Force | Measure-Object Length -Sum).Sum / 1MB), 2) }},
        @{n='FolderPath';e={ $_.FullName }} |
      Where-Object { $_.Size }
        
    # If more than one version of SEP is available older versions can be removed.
    if (([Array]$SEPVersions).Count -gt 1) {
      Write-Host "$($ComputerName): The following versions of SEP are installed:" -ForegroundColor Green
      $SEPVersions
    
      # Loop through all but the first (newest) version of SEP.
      $SEPVersions[1..$($SEPVersions.Count - 1)] | ForEach-Object {
        if ($pscmdlet.ShouldProcess("Removing $($_.FolderPath)")) {
          if ($Force -or $pscmdlet.ShouldContinue("Removing $($_.FolderPath) will free $($_.Size) MB.", "")) {
            Remove-Item $_.FolderPath -Recurse -ErrorAction SilentlyContinue
          }
        }
      }
    } elseif (-not $SEPVersions) {
      Write-Host "$($ComputerName): No SEP versions found." -ForegroundColor Yellow
    } else {
      Write-Host "$($ComputerName): The following versions of SEP are installed:" -ForegroundColor Green
      $SEPVersions
    }
  } else {
    Write-Host "$($ComputerName): Could not find or access a definition folder." -ForegroundColor Red
  }
}