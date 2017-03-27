function Get-KSADReport {
  # .SYNOPSIS
  #   Get an AD report definition from XML.
  # .DESCRIPTION
  #   Get-KSADReport loads report definitions from XML.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.AD.Report
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     02/07/2014 - Chris Dent - Updated XML structure.
  #     01/07/2014 - Chris Dent - Modified to use ConvertFrom-KSXPathNode.
  #     20/06/2014 - Chris Dent - First release
  
  [CmdLetBinding(DefaultParameterSetName = 'AllReports')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'ReportByID')]
    [ValidateNotNullOrEmpty()]
    [String]$ID,
    
    [ValidateScript( { Test-Path $_ } )]
    [String]$FileName = "$psscriptroot\..\var\reports.xml",
    
    [Switch]$Enabled
  )

  $XPathNavigator = New-KSXPathNavigator $FileName

  $CommonProperties = $XPathNavigator.Select("/ADReports/SharedConfiguration/Properties/Property") | ConvertFrom-KSXPathNode -ToHashtable
  $CalculatedProperties = $XPathNavigator.Select("/ADReports/SharedConfiguration/CalculatedProperties/Property") | ConvertFrom-KSXPathNode -ToHashtable
  
  $XPathExpression = switch ($pscmdlet.ParameterSetName) {
    'AllReports'   { $XPathNavigator.Compile("/ADReports/Reports/Report") }
    'ReportByID'   { $XPathNavigator.Compile("/ADReports/Reports/Report[translate(ID, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 'abcdefghijklmnopqrstuvwxyz')='$($ID.ToLower())']") }
  }
  
  $XPathNavigator.Select($XPathExpression) | ForEach-Object {
    $Report = New-Object PSObject
    $Report.PSObject.TypeNames.Add("KScript.AD.Report")
  
    $_.Select("./*") | ForEach-Object {
      $Node = $_

      $Value = switch ($_.Name) {
        'CalculatedProperties' { $Node.Select('./Property') | ConvertFrom-KSXPathNode -ToHashtable -MergeHashtable $CalculatedProperties; break }
        'Properties'           { $Node.Select('./Property') | ConvertFrom-KSXPathNode -ToHashtable -MergeHashtable $CommonProperties; break }
        'Recipients'           { $Node | ConvertFrom-KSXPathNode -ToArray; break }
        default                { $Node | ConvertFrom-KSXPathNode }
      }
      
      Add-Member $Node.Name -MemberType NoteProperty -Value $Value -InputObject $Report
    }

    if ($Enabled -and $Report.Enabled) {
      $Report
    } elseif (-not $Enabled) {
      $Report
    }
  }
}