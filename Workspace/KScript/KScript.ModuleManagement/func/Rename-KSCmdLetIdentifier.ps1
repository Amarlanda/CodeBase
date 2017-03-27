function Rename-KSCmdLetIdentifier {
  # .SYNOPSIS
  #   Rename owner identifiers in CmdLets.
  # .DESCRIPTION
  #   This CmdLet attempts to update CmdLet names (public and private) and update namespace declarations to aid refactoring. For example, references to a CmdLet named Get-AAThing can be replaced with Get-BBThing. The CmdLet may also be used to inject identifiers provided the CmdLet uses an approved verb.
  #
  #   Modules are expected to be named in the form <GlobalIdentifier>.<ModuleDescription>.
  #
  #   Files are expected to be named as functions (used to build the list of available modules).
  #
  #   Any new file names should be set prior to executing this script as a TFS operation.
  #
  #   Note: This CmdLet is thorough and it may take some time to run.
  # .PARAMETER ExcludeModule
  #   Exclude the specified modules when refactoring.
  # .PARAMETER FileName
  #   The full path to the script file to modify.
  # .PARAMETER NewIdentifier
  #   The new identifier to use, typically a 2 character string.
  # .PARAMETER NewNamespace
  #   Replace a .NET namespace declaration within the file with this value. Both old and new namespace values must be specified.
  # .PARAMETER OldIdentifier
  #   The old identifer (if any).
  # .PARAMETER OldNamespace
  #   Any existing namespace value. Both old and new namespace values must be specified.
  # .EXAMPLE
  #   Rename-KSCmdLetIdentifier AA BB -FileName C:\Stuff\ScriptFile.ps1
  # .EXAMPLE
  #   Get-ChildItem C:\Stuff\Module | Rename-KSCmdLetIdentifier -NewIdentifier BB
  # .EXAMPLE
  #   Rename-KSCmdLetIdentifier AA BB -FileName C:\Stuff\ScriptFile.ps1 -OldNamespace thing.old -NewNamespace thing.new
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/01/2015 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Position = 1)]
    [String]$OldIdentifier,

    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [String]$NewIdentifier,
  
    [String]$OldNamespace,
    
    [String]$NewNamespace,
  
    [String[]]$ExcludeModule,
  
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Alias('FullName')]
    [String]$FileName
  )
  
  begin {
    # This is a bit misused, a problem for later.
    $WorkspacePath = "$Script:WorkspacePath\KScript"
 
    # Cache CmdLet names from the workspace.
    $CmdLetNames = @{}
    Get-ChildItem $WorkspacePath\*\func\*.ps1 | ForEach-Object {
      $CmdLetNames.Add($_.BaseName, "")
    }
    
    # Cache verb names
    $Verbs = @{}
    Get-Verb | ForEach-Object {
      $Verbs.Add($_.Verb, "")
    }
  }
  
  process {
    if ((Test-Path $FileName -PathType Leaf) -and ($FileName -like '*.ps1' -or $FileName -like '*.psm1' -or $FileName -like '*.ps1xml')) {
      Write-Progress -Activity "Checking and updating file content" -Status $_.FullName

      $ChangeCount = 0
      
      # Build a file-specific cache.
      $AvailableCmdLets = $CmdLetNames
      $FuncPrivPath = $null
      if (Test-Path "$(Split-Path $FileName)\func-priv") {
        $FuncPrivPath = "$(Split-Path $FileName)\func-priv"
      } elseif (Test-Path "$(Split-Path $FileName)\..\func-priv") {
        $FuncPrivPath = "$(Split-Path $FileName)\..\func-priv"
      }
      if ($FuncPrivPath) {
        Get-ChildItem $FuncPrivPath | ForEach-Object {
          if (-not $AvailableCmdLets.Contains($_.BaseName)) {
            $AvailableCmdLets.Add($_.BaseName, "")
          }
        }
      }

      $NewContent = Get-Content $FileName | ForEach-Object {
        $Line = $_
        
        if ($psboundparameters.ContainsKey("OldNamespace") -and $psboundparameters.ContainsKey("NewNamespace")) {
          if ($Line -like "*$OldNamespace*") {
            $Line = $Line -replace ($OldNamespace -replace '\.', '\.'), $NewNamespace
            $ChangeCount++
          }
        }
        
        $_.Split(' ', [StringSplitOptions]::RemoveEmptyEntries) | 
          Where-Object { $_ -match '^(\$?\(?|'')(?<CmdLet>[A-Z0-9]+(-[A-Z0-9]+)?)\)?' } |
          ForEach-Object {
            $HasChanged = $false
          
            $OldName = $matches.CmdLet

            $Verb = $Verbs.Keys |
              Where-Object { $OldName -match "^$_" } |
              Sort-Object { $_.Length } -Descending |
              Select-Object -First 1
            
            if ($Verb) {
              if ($OldName -match "^\`$?\(?($($Verb)-)") {
                $Verb = $matches[1]
              }
              
              if ($OldName -notmatch "^$Verb$NewIdentifier") {
                if ($psboundparameters.ContainsKey("OldIdentifier") -and $OldName -match "^$Verb$OldIdentifier") {
                  $NewName = $OldName -replace "$Verb$OldIdentifier", "$Verb$NewIdentifier"
                  $HasChanged = $true
                } else {
                  $NewName = $OldName -replace "$Verb", "$Verb$NewIdentifier"
                  $HasChanged = $true
                }
              } else {
                $NewName = $OldName
              }
              
              if ($AvailableCmdLets.Contains($NewName)) {
                if ($HasChanged) { $ChangeCount++ }
                $Line = $Line -replace $OldName, $NewName
              }
            }
          }
          
        $Line
      } | Out-String

      New-Object PSObject -Property ([Ordered]@{
        FilePath    = (Split-Path $FileName -Leaf)
        ChangeCount = $ChangeCount
      })
      
      if (-not $psboundparameters.ContainsKey("WhatIf")) {
        $NewContent | Set-Content $FileName
      }
    }
  }
}