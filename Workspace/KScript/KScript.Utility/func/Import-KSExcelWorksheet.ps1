function Import-KSExcelWorksheet {
  # .SYNOPSIS
  #   Import from Excel using the Microsoft Access Database Engine.
  # .DESCRIPTION
  #   Import-KSExcelWorksheet uses the Microsoft Access Database Engine to read from Excel files. The Microsoft Access Database Engine can read from Excel without needing to use the Excel COM Object.
  # .PARAMETER FileName
  #   The Excel file to read. This function is only tested against xlsx files.
  # .PARAMETER FirstDataRow
  #   If a header is read data will be assumed to begin immediately after the header. If data begins later this parameter may be used to define a starting point.
  #
  #   If a header is supplied data is assumed to begin on the first line.
  # .PARAMETER Header
  #   A list of header values in the order they appear in the spreadsheet. Columns beyond the defined header will be dropped.
  # .PARAMETER HeaderRowNumber
  #   By default, an automatically read header row is assumed to appear on the first line. If the header row appears later this parameter should be specified.
  # .PARAMETER IgnoreEmptyRows
  #   Rows which contain no data may be optionally dropped from the output.
  # .PARAMETER TypedHeader
  #   A typed header may be used to convert the default System.String values to specific .NET types. For example, a column containing a date may be parsed and returned as a System.DateTime type.
  # .PARAMETER WorksheetName
  #   All worksheets are returned by default. A specific worksheet name may be specified using this parameter.
  # .EXAMPLE
  #   Import-KSExcelWorksheet ExcelFile.xlsx
  #
  #   Import all worksheets, the header for each sheet is read automatically from the first line of the sheet.
  # .EXAMPLE
  #   Import-KSExcelWorksheet ExcelFile.xlsx -Header "First column", "Second column"
  #
  #   Import all worksheets, return the first and second column from each sheet.
  # .EXAMPLE
  #   Import-KSExcelWorksheet ExcelFile.xlsx -WorksheetName "Some Worksheet" -IgnoreEmptyRows
  #
  #   Import the "Some Worksheet" worksheet, ignore empty rows.
  # .EXAMPLE
  #   $Header = [Ordered]@{
  #     'Log Date'     = [DateTime]
  #     'Description'  = [String]
  #     'Count'        = [UInt32]
  #     'Success Date' = [Nullable``1[[DateTime]]]
  #   }
  #   Import-KSExcelWorksheet ExcelFile.xlsx -WorkSheetName "Some Worksheet" -TypedHeader $Header -FirstDataRow 2 -IgnoreEmptyRows
  #
  #   Import the "Some Worksheet" worksheet. Start reading on the second row and use the ordered hashtable to read and convert the imported values.
  # .LINK
  #   http://www.microsoft.com/en-gb/download/details.aspx?id=13255)
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/06/2014 - Chris Dent - First release

  [CmdLetBinding(DefaultParameterSetName = 'AutomaticHeader')]
  param(
    [Parameter(Mandatory = $true, Position = 1, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [ValidateScript( { Test-Path $_ -Filter *.xlsx -PathType Leaf } )]
    [Alias('FullName')]
    [String]$FileName,
    
    [String]$WorksheetName = "*",
    
    [UInt32]$FirstDataRow = 1,
    
    [Parameter(ParameterSetName = 'AutomaticHeader')]
    [UInt32]$HeaderRowNumber = 1,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'ManualHeader')]
    [ValidateNotNullOrEmpty()]
    [String[]]$Header,
    
    [Parameter(Mandatory = $true, ParameterSetName = 'TypedHeader')]
    [ValidateScript( { $_.Keys.Count -gt 1 } )]
    [Collections.Specialized.OrderedDictionary]$TypedHeader,
    
    [Switch]$IgnoreEmptyRows
  )

  begin {
    Get-ChildItem "env:\ProgramFiles*" | ForEach-Object {
      if (Test-Path "$($_.Value)\Common Files\Microsoft Shared\OFFICE14\ACEOLEDB.dll") {
        $ProviderInstalled = $true
      }
    }
    if (-not $ProviderInstalled) {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "Microsoft Access Database Engine must be installed."),
        "InvalidOperation",
        [Management.Automation.ErrorCategory]::InvalidOperation,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)    
    }
    
    # Fix up the sheet name. OLEDB seems to replace periods with hashes.
    $WorksheetName = $WorksheetName -replace '\.', '#'

    # Fix up the parameters    
    if ($pscmdlet.ParameterSetName -eq 'AutomaticHeader' -and $FirstDataRow -eq 1) {
      # The header row is automatically decremented during read to account for a 0-based index.
      $FirstDataRow = $HeaderRowNumber
    }
    if ($FirstDataRow -lt $HeaderRowNumber -and $pscmdlet.ParameterSetName -eq 'AutomaticHeader') {
      $ErrorRecord = New-Object Management.Automation.ErrorRecord(
        (New-Object ArgumentException "The header row ($HeaderRowNumber) must appear before the first data row ($FirstDataRow)."),
        "ArgumentException",
        [Management.Automation.ErrorCategory]::InvalidArgument,
        $pscmdlet)
      $pscmdlet.ThrowTerminatingError($ErrorRecord)
    }
  }
  
  process {
    # Ensure we have a full path to the file.
    $FileName = (Get-Item $FileName).FullName
  
    $ConnectionString = "Provider=Microsoft.ACE.OLEDB.12.0;Data Source=$FileName;Extended Properties=""Excel 12.0;IMEX=1;HDR=NO;TypeGuessRows=0;ImportMixedTypes=Text"""
    
    try {
      $Connection = New-Object Data.OleDb.OleDbConnection $ConnectionString
      $Connection.Open()
    } catch {
      Write-Error $_.Exception.Message
    }
  
    if ($?) {
      $Sheets = $Connection.GetOleDbSchemaTable([Data.OleDb.OleDbSchemaGuid]::Tables, @($null, $null, $null, "TABLE"))
      $Sheets |
        Where-Object { $_.TABLE_NAME -like "$WorksheetName`$" -or $_.TABLE_NAME -like "'$WorkSheetName`$'" } |
        ForEach-Object {
          $Command = $Connection.CreateCommand()
          $Command.CommandText = "SELECT * FROM [$($_.'TABLE_NAME')]"

          $DataSet = New-Object Data.DataSet
         
          $Adapter = New-Object Data.OleDb.OleDbDataAdapter($Command)
          $RowCount = $Adapter.Fill($DataSet)

          if ($pscmdlet.ParameterSetName -eq 'AutomaticHeader') {
            $Header = ($DataSet.Tables.Rows[($HeaderRowNumber - 1)] | ConvertTo-Csv | ConvertFrom-Csv).PSObject.Properties | Where-Object Value | Select-Object -Expand Value
          } elseif ($pscmdlet.ParameterSetName -eq 'TypedHeader') {
            $Header = $TypedHeader.Keys
          }
          
          for ($i = $FirstDataRow; $i -lt $RowCount; $i++) {
            if ($IgnoreEmptyRows -and -not ($DataSet.Tables.Rows[$i].ItemArray | Where-Object { $_ -isnot [DBNull] })) {
              # Ignore this row, no data.
            } else {
              $Row = $DataSet.Tables.Rows[$i] | ConvertTo-Csv | Select-Object -Last 1 | ConvertFrom-Csv -Header $Header
              
              # If the return values should have types adjusted
              if ($pscmdlet.ParameterSetName -eq 'TypedHeader') {
                $Row.PSObject.Properties | ForEach-Object {
                  if ($_.TypedNameOfValue -ne $TypedHeader[$_.Name].FullName) {
                    # Attempt to replace this member
                    if ($TypedHeader[$_.Name] -in [DateTime], [Nullable``1[[DateTime]]]) {
                      # Handle DateTime types
                      $Value = $_.Value; $DateTime = Get-Date
                      if ([DateTime]::TryParse($Value, [Ref]$DateTime)) {
                        $Value = $DateTime
                      } else {
                        Write-Verbose "Import-Excel: Failed to convert value ($Value) to DateTime, returning String"
                      }
                      Add-Member $_.Name -MemberType NoteProperty -Value $Value -InputObject $Row -Force
                    } else {
                      # Handle other types
                      $Value = $_.Value; $Type = $TypedHeader[$_.Name]
                      try {
                        $Value = [Convert]::ChangeType($Value, $Type)
                      } catch {
                        Write-Verbose "Import-Excel: Failed to convert value ($Value) to $Type, returning String"
                      }
                      Add-Member $_.Name -MemberType NoteProperty -Value $Value -InputObject $Row -Force
                    }
                  }
                }
                # Revert to the original property order.
                $Row = $Row | Select-Object $Header
              }
              $Row
            }
          }
        }
      
      $Connection.Close()
    }
  }
}
