function Update-KSDDIMapping {
  # .SYNOPSIS
  #   Update the ddi-mapping.xml file from a spreadsheet.
  # .DESCRIPTION
  #   The update script expects the following:
  #
  #     1. A spreadsheet containing a worksheet named DDI.
  #     2. The header for the worksheet at line 4.
  #     3. Data to begin at line 5.
  #     4. The following header values: Site Code, Short Code, KPMG Office Location, DDI Range(s), 5 digit start, 5 digit end, Unity Server.
  #     5. The DDI Range(s) field to contain "<Area code> <Partial Number> <Range Start>-<Range End> (except for Operator numbers).
  #
  #  The spreadsheet is maintained by BT (kpmg.smac@bt.com).
  # .PARAMETER InputFile
  #   The path and name of the spreadsheet to import.
  # .PARAMETER OutputFile
  #   The path to the ddi-mapping.xml file to write. Note that the ddi-mapping.xml file is updated with the module, therefore a path to a master resource must be specified.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Update-KSDDIMapping -InputFile "C:\Temp\KPMG Short Codes and DDI Ranges_New.xls" -OutputFile "C:\Workspace\KScript\KScript.AccountMaintenance\var\ddi-mapping.xml"
  #
  #   Update the ddi-mapping file in a workspace (development) branch.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/11/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, Position = 1)]
    [ValidateScript( { Test-Path $_ -PathType Leaf } )]
    [ValidateNotNullOrEmpty()]
    [String]$InputFile,
    
    [Parameter(Mandatory = $true, Position = 2)]
    [ValidateNotNullOrEmpty()]
    [String]$OutputFile
  )
  
  Import-KSExcelWorksheet $InputFile -WorksheetName "DDIs" -HeaderRowNumber 4 |
    ForEach-Object {
      $NormalisedObject = New-Object PSObject
      $_.PSObject.Properties | ForEach-Object {
        Add-Member ($_.Name -replace '  ', ' ').Trim() -MemberType NoteProperty -Value $_.Value -InputObject $NormalisedObject
      }
      $NormalisedObject
    } |
    Where-Object { $_."Short Code" -and $_."DDI Range(s)" -match '^(?<DDIFragment>\d+ \d+) (?<FromExt>\d+)-(?<ToExt>\d+)$' } |
    Select-Object `
      @{n='OfficeCode';e={ $_."Short Code" }},
      @{n='FromExt';e={ $matches.FromExt }},
      @{n='ToExt';e={ $matches.ToExt }},
      @{n='OfficeName';e={ $_."KPMG Office Location" }},
      @{n='DDINumber';e={ $matches.DDIFragment }} |
    ForEach-Object {
      $_.DDINumber = $_.DDINumber -replace '^0', '+44 '
      $_
    } |
      Sort-Object OfficeCode, FromExt |
      ConvertTo-KSXml -RootNodeName DDIMappings -ChildNodeName DDIMapping -IncludeTypeNames $false |
      Out-File $OutputFile -Force
}