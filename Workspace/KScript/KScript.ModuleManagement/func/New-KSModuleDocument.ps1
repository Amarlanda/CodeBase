function New-KSModuleDocument {
  # .SYNOPSIS
  #   Create a new CSV file describing the functions in a module.
  # .DESCRIPTION
  #   Generates an CSV file summarising the content of a module based on the initial content table and function descriptions.
  # .PARAMETER Name
  #   The name of the module within the workspace.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   New-KSModuleDocument SomeModule
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1)]
    [String]$Name
  )

  $CmdLets = @{}
  Get-ChildItem "$Script:WorkspacePath\KScript\$Name\*\*" -File | Where-Object { $_.FullName -match '\\func\\|\\func-priv\\' -and $_.Extension -in '.ps1', '.psm1' } | ForEach-Object {

    $CmdLet = New-Object PSObject -Property ([Ordered]@{
      Name         = $_.BaseName;
      Access       = "Public";
      Description  = "";
      Author       = "";
      Team         = "";
      LastModified = "";
      ModifiedBy   = "";
      Source       = $_.FullName;
    })

    if ($_.FullName -match '-priv\\') {
      $CmdLet.Access = "Private"
    }
    
    Get-Content $_.FullName | ForEach-Object {
      if ($SynopsisRead) {
        $CmdLet.Description = $_ -replace '  #   '
        $SynopsisRead = $false
      }
      if ($ChangeLogRead) {
        if ($_ -match '^  # *(\S+) - ([^\-]+) - ') {
          $CmdLet.LastModified = $matches[1]
          $CmdLet.ModifiedBy  = $matches[2]
        }
        $ChangeLogRead = $false
      }
      
      switch -regex ($_) {
        '^  # \.SYNOPSIS'      { $SynopsisRead = $true }
        '^  # *Author: *(.+)$' { $CmdLet.Author = $matches[1] }
        '^  # *Team: *(.+)$'   { $CmdLet.Team = $matches[1] }
        '^  # *Change log:'    { $ChangeLogRead = $true }
      }
    }
    
    $CmdLets.Add($CmdLet.Name, $CmdLet)
  }

  if (-not (Test-Path "$WorkspacePath\KScript\$Name\doc")) {
    New-Item "$WorkspacePath\KScript\$Name\doc" -ItemType Directory | Out-Null
  }
  $CmdLets.Values | Sort-Object Access, Name | Select-Object * -Exclude Source | Export-Csv "$WorkspacePath\KScript\$Name\doc\Functions.csv" -NoTypeInformation
}