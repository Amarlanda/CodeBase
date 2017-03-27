function New-KSModuleSPPage {
  # .SYNOPSIS
  #   Create a new HTML document suitable for pasting into SharePoint 2007's HTML wiki page editor.
  # .DESCRIPTION
  #   New-KSModuleSPPage attempts to generate HTML which can be pasted directly into a SharePoint 2007 wiki page editor (HTML view).
  # .PARAMETER Name
  #   The name of the module within the workspace.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   New-KSModuleSPPage SomeModule
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     04/11/2014 - Chris Dent - Do not run Get-Help if the command is not locally available.
  #     03/11/2014 - Chris Dent - Fixed to account for directory structure change.
  #     08/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1)]
    [String]$Name
  )

  $PageURL = "http://sites.eu.kworld.kpmg.com/sites/infrastructure/department/itservices/coretechnologies/KScript/$Name.aspx"
  $FunctionsDocument = "$WorkspacePath\KScript\$Name\doc\Functions.csv"
  
  $StringBuilder = New-Object Text.StringBuilder
  
  if (Test-Path $FunctionsDocument) {
    $Functions = Import-Csv $FunctionsDocument |
      Where-Object { Get-Command $_.Name -ErrorAction SilentlyContinue } |
      Select-Object Name, Description, Author, @{n='Last modified';e={ $_.LastModified }}, @{n='Modified by';e={ $_.ModifiedBy }}
    
    $StringBuilder.AppendLine("<DIV><P><FONT size=1 color=#969696>Back to [[Module reference]]</FONT></P></DIV>") | Out-Null
    
    #
    # Contents
    #

    $StringBuilder.AppendLine("<DIV><STRONG><FONT size=4>Contents</FONT></STRONG></DIV>") | Out-Null
    $StringBuilder.AppendLine("&nbsp;") | Out-Null
    $StringBuilder.AppendLine("<DIV>") | Out-Null
    $StringBuilder.AppendLine("<A HREF='$PageURL#ModuleInformation'>Module information</A><BR />") | Out-Null
    $StringBuilder.AppendLine("<A HREF='$PageURL#Functions'>Functions</A><BR />") | Out-Null
    $StringBuilder.AppendLine("</DIV>") | Out-Null
    $StringBuilder.AppendLine("&nbsp;<HR>&nbsp;") | Out-Null
    
    #
    # ModuleInformation
    #

   
    $StringBuilder.AppendLine("<DIV><A Name='ModuleInformation'></A><STRONG><FONT size=4>Module information</FONT></STRONG></DIV>") | Out-Null
    $StringBuilder.AppendLine("&nbsp;") | Out-Null

    $ModuleManifest = Get-KSModuleManifest $Name

    $StringBuilder.AppendLine("<DIV>") | Out-Null
    $StringBuilder.AppendLine("<P>$([Web.HttpUtility]::HtmlEncode($ModuleManifest['Description']))</P>") | Out-Null
    $StringBuilder.AppendLine("<UL>") | Out-Null
    $StringBuilder.AppendLine("<LI>Module version: $($ModuleManifest['ModuleVersion'])</LI>") | Out-Null
    $StringBuilder.AppendLine("<LI>Author: $($ModuleManifest['Author'])</LI>") | Out-Null
    $StringBuilder.AppendLine("<LI>Page updated: $(Get-Date -Format 'dddd d MMMM yyyy')</LI>") | Out-Null
    $StringBuilder.AppendLine("</UL>") | Out-Null
    $StringBuilder.AppendLine("</DIV>") | Out-Null
    $StringBuilder.AppendLine("&nbsp;<HR>&nbsp;") | Out-Null
    
    #
    # Functions
    #
    
    $StringBuilder.AppendLine("<DIV><A Name='Functions'></A><STRONG><FONT size=4>Functions</FONT></STRONG></DIV>") | Out-Null
    $StringBuilder.AppendLine("&nbsp;") | Out-Null
    $StringBuilder.AppendLine("<DIV>") | Out-Null
    
    $HtmlFragment = $Functions | ConvertTo-Html -Fragment | Out-String
    $HtmlFragment = $HtmlFragment -replace '<table>', '<TABLE style="WIDTH: 100%; BORDER-COLLAPSE: collapse; FONT-SIZE: 1em" border=1>'
    $HtmlFragment = $HtmlFragment -replace '<th>', '<th style="background-color: #98C6F3;">'
    $HtmlFragment = $HtmlFragment -replace '<colgroup>.+</colgroup>\r\n'
    $HtmlFragment = $HtmlFragment -replace '<tr><td>([^<]+)', '<tr><td><a href=''PAGEURL#$1''>$1</a>'
    $HtmlFragment = $HtmlFragment -replace 'PAGEURL', $PageURL
    
    $StringBuilder.Append($HtmlFragment) | Out-Null

    $StringBuilder.AppendLine("</DIV>") | Out-Null
    $StringBuilder.AppendLine("&nbsp;<HR>&nbsp;") | Out-Null

    #
    # Function help
    #
    
    $Functions | ForEach-Object {
      $StringBuilder.AppendLine("<DIV><A Name='$($_.Name)'></A><STRONG><FONT size=4>$($_.Name)</FONT></STRONG></DIV>") | Out-Null
      $StringBuilder.AppendLine("&nbsp;") | Out-Null

      if (Get-Command $_.Name) {
        # This section assumes Help for the module has been updated in the local session prior to processing a release.
        # This is used because generating the Syntax block will be extremely difficult otherwise.
        $Help = Get-Help $_.Name
        
        if ($Help.Synopsis) {
        
          # Synopsis
          
          $StringBuilder.AppendLine("<DIV><STRONG><FONT size=2>Synopsis</FONT></STRONG></DIV>") | Out-Null
          $StringBuilder.AppendLine("<P>$([Web.HttpUtility]::HtmlEncode($Help.Synopsis))</P>") | Out-Null

          # Syntax

          $StringBuilder.AppendLine("<DIV><STRONG><FONT size=2>Syntax</FONT></STRONG></DIV>") | Out-Null
          if (($Help.Syntax | Out-String) -match 'syntaxItem') {
            $Syntax = ($Help | Out-String) -cmatch '(?>SYNTAX)((?:[\r\n]|.)+\])'
          } else {
            $Syntax = $Help.Syntax | Out-String
          }
          [Array]$Lines = $Syntax -split '\r\n' | Where-Object { $_ }
          $($SyntaxLine = $null
            for ($i = 0; $i -lt $Lines.Count; $i++) {
              if ($Lines[$i] -match "^$($_.Name)") {
                if ($SyntaxLine) { $SyntaxLine }
                $SyntaxLine = $Lines[$i]
              } else {
                $SyntaxLine = "$SyntaxLine$($Lines[$i])"
              }
            }
            if ($SyntaxLine) { $SyntaxLine }
          ) | ForEach-Object {
            $StringBuilder.AppendLine("<P style='font-family: Consolas'>$([Web.HttpUtility]::HtmlEncode($_))</P>") | Out-Null
          }
        
          # Description
          
          $StringBuilder.AppendLine("<DIV><STRONG><FONT size=2>Description</FONT></STRONG></DIV>") | Out-Null
          $Description = ($Help.Description.Text -split '\n') + ""
          $i = 0
          $Description = $( do {
              $Line = [Web.HttpUtility]::HtmlEncode($Description[$i])
            
              if (-not $BlockType) {
                $BlockContent = @()
                $BlockType = switch -RegEx ($Line) {
                  '^ +\* .+'        { "UnorderedList"; break }
                  '^ +\d+\. .+'     { "OrderedList"; break }
                  '^ +(1 +){5}1'    { "ByteStructure"; break }
                  '&lt;\S+&gt;'     { "XML"; break }
                  '^ +(\S.*  +)+.+' { "Table"; break }
                  '^ +(.+)+'        { "List"; break }
                  default           { "Paragraph" }
                }
              }
            
              if (-not $Line.Trim() -and $BlockContent) {
                switch ($BlockType) {
                  'UnorderedList' { $StringBuilder.Append(("<UL>" + (($BlockContent | ForEach-Object { "<LI>$($_ -replace '^ *\* *')</LI>" }) -join '') + "</UL>")) | Out-Null; break }
                  'OrderedList'   { $StringBuilder.Append(("<OL>" + (($BlockContent | ForEach-Object { "<LI>$($_ -replace '^ *\d+\. *')</LI>" }) -join '') + "</OL>")) | Out-Null; break }
                  'ByteStructure' { $StringBuilder.Append(("<FONT style='font-family: Consolas'>" + ($BlockContent | ForEach-Object { "$($_ -replace ' ', '&nbsp;')<BR />" }) + "</FONT>")) | Out-Null; break }
                  'XML'           { $StringBuilder.Append(("<FONT style='font-family: Consolas'>" + ($BlockContent | ForEach-Object { "$($_ -replace ' ', '&nbsp;')<BR />" }) + "</FONT>")) | Out-Null; break }
                  'Table'         {
                    $StringBuilder.AppendLine('<TABLE style="WIDTH: 50%; BORDER-COLLAPSE: collapse; FONT-SIZE: 1em" border=1>') | Out-Null
                    $BlockContent | ForEach-Object {
                      $StringBuilder.AppendLine(("<TR><TD>" + (($_ -split '  +' | ForEach-Object { $_.Trim() } | Where-Object { $_ }) -join '</TD><TD>') + "</TD></TR>")) | Out-Null
                    }
                    $StringBuilder.AppendLine("</TABLE>") | Out-Null
                  }
                  'List'          { $BlockContent | ForEach-Object { if ($_ -match '(\s+)') { $Count = $matches[1].Length } else { $Count = 0 }; $StringBuilder.Append(("$('&nbsp;' * $Count)$($_.Trim())<BR />")) | Out-Null }; break }
                  'Paragraph'     { $StringBuilder.AppendLine(("<P>" + ($BlockContent | ForEach-Object { $_ }) + "</P>")) | Out-Null; break }
                }
                $BlockType = $null
              }
              
              if ($BlockType) {
                $BlockContent += $Line
              }
            
              $i++
            } until ($i -ge $Description.Count)
          ) | Out-String
          $Description = $Description.Trim()
          $Description = $Description -replace '(?<!</P>)$', '&nbsp;'
          
          $StringBuilder.Append($Description) | Out-Null
          
          # Notes
          
          if ($Help.alertSet) {
            $StringBuilder.AppendLine("<DIV><STRONG><FONT size=2>Change log</FONT></STRONG></DIV>") | Out-Null
            $StringBuilder.AppendLine("&nbsp;") | Out-Null
            $StringBuilder.AppendLine("<DIV>") | Out-Null
            
            [Array]$Lines = (($Help.alertSet | Out-String) -replace '([\r\n]|.)+Change log:\r\n') -split '\r\n' | Where-Object { $_ } | ForEach-Object { $_.Trim() }
            $HtmlFragment = $(
              $LogLine = $null
              for ($i = 0; $i -lt $Lines.Count; $i++) {
                if ($Lines[$i] -match '^\d+') {
                  if ($LogLine) { $LogLine }
                  $LogLine = $Lines[$i]
                } else {
                  $LogLine = "$LogLine $($Lines[$i])"
                }
              }
              if ($LogLine) { $LogLine }
            ) | ForEach-Object {
              $Items = $_ -split ' - ' | Where-Object { $_ } | ForEach-Object { $_.Trim() }
              
              New-Object PSObject -Property ([Ordered]@{
                Date = $Items[0]
                Who  = $Items[1]
                What = $Items[2]
              })
            } | ConvertTo-Html -Fragment | Out-String
            $HtmlFragment = $HtmlFragment -replace '<table>', '<TABLE style="WIDTH: 70%; BORDER-COLLAPSE: collapse; FONT-SIZE: 1em" border=1>'
            $HtmlFragment = $HtmlFragment -replace '<th>', '<th style="background-color: #98C6F3;">'
            $HtmlFragment = $HtmlFragment -replace '<colgroup>.+</colgroup>\r\n'
            
            $StringBuilder.Append($HtmlFragment) | Out-Null
            $StringBuilder.AppendLine("</DIV>") | Out-Null
          }
        }
      }
      $StringBuilder.AppendLine("&nbsp;<HR>&nbsp;") | Out-Null
    }
  }
  ConvertTo-Html -Body $StringBuilder.ToString() | Out-String | Out-File "$WorkspacePath\KScript\$Name\doc\Module.html" -Encoding ASCII
}