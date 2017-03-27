function Export-KSExcelWorksheet {
  # .SYNOPSIS
  #   Export objects to an Excel Worksheet.
  # .DESCRIPTION
  #   Export-KSExcelWorksheet uses the EPPlus library to create Excel worksheets based from an input pipeline.
  #
  #   Data written to the spreadsheet is normalised based on the first object in the input pipeline. If automatic normalisation is not desirable all input data must be normalised outside of this function.
  # .PARAMETER Append
  #   Append the Object to the end of the specified Worksheet. If the worksheet does not exist it will be created as normal.
  # .PARAMETER Clobber
  #   Overwrite any existing file of the same name.
  # .PARAMETER FileName
  #   The name of the Excel file to create (including extension).
  # .PARAMETER Object
  #   The content to write to the Worksheet.
  # .PARAMETER WorksheetName
  #   The name of the Worksheet to use.
  # .INPUTS
  #   System.String
  #   System.Object[]
  # .EXAMPLE
  #   Get-Process | Export-KSExcelWorksheet "C:\Temp\Processes.xlsx" -WorksheetName "Processes"
  # .LINKS
  #   http://epplus.codeplex.com/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     17/10/2014 - Chris Dent - Added support for arrays of values (joined with a carriage return)
  #     01/10/2014 - Chris Dent - Changed to epplus 4.0 Beta 2 to resolve a write bug for large worksheets.
  #     29/09/2014 - Chris Dent - Added incremental saving.
  #     25/07/2014 - Chris Dent - Suppressed Worksheet return when replacing an existing sheet.
  #     17/07/2014 - Chris Dent - Added data normalisation. Fixed error handling for locked files.
  #     01/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [String]$FileName,

    [ValidateNotNullOrEmpty()]
    [String]$WorksheetName,
    
    [Switch]$MoveToStart,
    
    [Parameter(ValueFromPipeline = $true)]
    [Object[]]$Object,
    
    [Switch]$Clobber,
    
    [Switch]$Append
  )
  
  begin {
    # A full path is required, if the file does not exist a file will be briefly created as a simple means of getting a full path
    if (Test-Path $FileName -PathType Leaf) {
      $FileName = (Get-Item $FileName).FullName
    } else {
      "" | Out-File $FileName
      $FileName = (Get-Item $FileName).FullName
      Remove-Item $FileName
    }
 
    if ($Clobber -and (Test-Path $FileName)) {
      # Throw a terminating error if the file cannot be written and Clobber is set.
      Remove-Item $FileName -ErrorAction Stop
    }
    
    if (-not $WorksheetName) {
      $WorksheetName = (Split-Path $FileName -Leaf) -replace '\.[^.]+$'
    }
 
    $FileInfo = New-Object IO.FileInfo $FileName
    try {
      $Package = New-Object OfficeOpenXml.ExcelPackage($FileInfo)
    } catch {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object InvalidOperationException $_.Exception.InnerException.Message),
        "InvalidOperationException",
        [Management.Automation.ErrorCategory]::InvalidOperation,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
    
    if ($Package.Workbook.Worksheets[$WorksheetName]) {
      if (-not $Append) {
        $Package.Workbook.Worksheets.Delete($WorksheetName) | Out-Null
        $Package.Workbook.Worksheets.Add($WorksheetName) | Out-Null
      }
      $Worksheet = $Package.Workbook.Worksheets[$WorksheetName]
    } else {
      $Worksheet = $Package.Workbook.Worksheets.Add($WorksheetName)
    }
    
    if ($MoveToStart) {
      $Package.Workbook.Worksheets.MoveToStart($WorksheetName) | Out-Null
    }
   
    if ($Append -and $Worksheet.Dimension.End.Row -ge 1) {
      $Row = $Worksheet.Dimension.End.Row + 1
    } else {
      $Row = 1
    }
    $FirstInPipeline = $true
  }

  process {
    if ($FirstInPipeline) {
      # Note: The header will be used to normalise results.
      $Header = $Object[0].PSObject.Properties | Select-Object -ExpandProperty Name
      $FirstInPipeline = $false
    }
    if ($Row -eq 1) {
      $Column = 1
      $Object[0].PSObject.Properties | ForEach-Object {
        $WorkSheet.Cells[$Row, $Column].Value = $_.Name
        $Column++
      }
      $Column--
      
      $Range = $Worksheet.Cells[1, 1, 1, $Column]
      $Range.Style.Font.Bold = $true
      $Range.Style.Fill.PatternType = [OfficeOpenXml.Style.ExcelFillStyle]::Solid
      $Range.Style.Fill.BackgroundColor.SetColor([Drawing.Color]::LightSteelBlue)
      
      $Worksheet.View.FreezePanes(2, 1) | Out-Null
      
      $Row++
    }

    $Object | ForEach-Object {
      $Column = 1
      
      # Normalise this row (according to the header)
      if ($Header) {
        $_ = $_ | Select-Object $Header
      }
      
      $_.PSObject.Properties | ForEach-Object {
        if ($_.Value -is [DateTime]) {
          $Worksheet.Cells[$Row, $Column].Value = $_.Value
          $Worksheet.Cells[$Row, $Column].Style.NumberFormat.Format = "dd/mm/yyyy hh:mm"
        } elseif ($_.Value -is [Array]) {
          $Worksheet.Cells[$Row, $Column].Value = $_.Value -join "`r`n"
        } elseif ($_.Value) {
          $Worksheet.Cells[$Row, $Column].Value = $_.Value
        }
        $Column++
      }
      
      $Row++
    }
  }
  
  end {
    if ($Worksheet.Dimension.Address) {
      # Add the auto-filter
      $Worksheet.Cells[$Worksheet.Dimension.Address].AutoFilter = $true

      # Set AutoFit
      $Worksheet.Cells[$Worksheet.Dimension.Address].AutoFitColumns()
    }
  
    $Package.Save()
  }
}