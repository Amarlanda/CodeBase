function Import-KSADTelephoneNumber {
  # .SYNOPSIS
  #   Import ipPhone, othertelephone and telephoneNumber from an Excel spreadsheet supplied by BT.
  # .DESCRIPTION
  #   Import-KSADTelephoneNumber is the entry point for importing telephoneNumber information into Active Directory.
  #
  #   Information stored in Active Directory is exported into the ARC directory (used by receptionists), Exchange and Lync (via the Offline Address List) and Cisco CallManager.
  # .PARAMETER FolderPath
  #   The script will act against any Excel spreadsheet present in FolderPath. The Excel file is archived in accordance with the log retention settings.
  # .PARAMETER WhatIf
  #   If WhatIf is set the script will run through all steps and generate internal reports.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Import-KSADTelephoneNumber
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     10/11/2014 - Chris Dent - Added lastLogonTimeStamp to debugging section.
  #     03/11/2014 - Chris Dent - Added blank givenName or sn checking, writes as a Warning to aid debugging.
  #     23/09/2014 - Chris Dent - Added blank ADName checking.
  #     17/09/2014 - Chris Dent - Added debugging section to PostContent. Made script live.
  #     15/09/2014 - Chris Dent - Added full change logging (to CSV, History\History.csv).
  #     01/09/2014 - Chris Dent - Allowed script to set phone numbers for disabled user accounts.
  #     29/08/2014 - Chris Dent - Fixed HTML report highlighting.
  #     28/08/2014 - Chris Dent - Added blank line suppression (if both ADName and Directory Number are blank).
  #     22/08/2014 - Chris Dent - BugFix: Trimmed input fields. Fixed number-in-use check.
  #     21/08/2014 - Chris Dent - Fixed output object, added check for blank IPPhone values. Test release.
  #     07/08/2014 - Chris Dent - First release.

  [CmdLetBinding(SupportsShouldProcess = $true)]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateScript( { Test-Path $_ -PathType Container } )]
    [String]$FolderName,
    
    [TimeSpan]$HistoryTimeSpan = (New-TimeSpan -Days 180)
  )

  Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript

  Get-ChildItem $FolderName -File -Filter *.xls* | ForEach-Object {

    # Import Lync session - Temporary
    
    if (-not $psboundparameters.ContainsKey("WhatIf") -and -not $LyncSessionImported) {
      Import-KSLyncSession
      if ($?) {
        $LyncSessionImported = $true
      } else {
        Write-KSLog "Failed to import Lync management session" -LogLevel Error
        $LyncSessionImported = $false
      }
    }

    Write-KSLog "Reading $($_.FullName)"
  
    $FileDate = $_.Name -replace '^AD Flags - |\.xlsx$'
  
    #
    # Clean the worksheet content
    #
    
    $Entries = Import-KSExcelWorksheet $_.FullName -Worksheet 'AD Flags' -IgnoreEmptyRows |
      Where-Object { $_.ADName.Trim() -or $_.'Directory Number'.Trim() } |
      ForEach-Object {
        New-Object PSObject -Property ([Ordered]@{
          ADName          = $_.ADName.Trim()
          FirstName       = $_.'First Name'.Trim()
          LastName        = $_.'Last Name'.Trim()
          Office          = $_.'User Location'.Trim()
          IPPhone         = $_.'Directory Number'.Trim()
          TelephoneNumber = $null
          OtherTelephone  = $null
          BTComment       = $_.Comments.Trim()
          KPMGComment     = $null
          Result          = $null
          LyncComment     = $null
          LyncResult      = $null
          KSADUser        = $null
        })
      }
    
    Write-KSLog "  Read $($Entries.Count) entries"
    
    if ($Entries) {
      #
      # Generate a timestamp
      #
      
      $TimeStamp = Get-Date
    
      #
      # Truncate the History file
      #
    
      if (Test-Path "$FolderName\History\History.csv") {
        Write-KSLog "Truncating $FolderName\History\History.csv"
        $History = Import-Csv "$FolderName\History\History.csv" | Where-Object { (Get-Date $_.TimeStamp) -gt ((Get-Date) - $HistoryTimeSpan) }
        $History | Export-Csv "$FolderName\History\History.csv" -NoTypeInformation
        $History = $null
      }
    
      #
      # Delete archived files
      #
      
      Get-ChildItem "$FolderName\ProcessedFiles" -Filter *.xls* |
        Where-Object { $_.LastWriteTime -lt (Get-Date).AddMonths(-1) } |
        Remove-Item
    
      #
      # Sanity check worksheet content
      #
      
      Write-KSLog "Sanity testing spreadsheet content"

      # Blank ADName testing
      $Entries | Where-Object { -not $_.ADName } | ForEach-Object {
        $_.Result = "Skipped"; $_.KPMGComment = "Blank ADName."
        Write-KSLog "  Skipped $($_.FirstName) $($_.LastName) - Blank ADName field."
      }
      
      # Blank IPPhone testing
      $Entries | Where-Object { -not $_.IPPhone } | ForEach-Object {
        $_.Result = "Skipped"; $_.KPMGComment = "Blank IPPhone."
        Write-KSLog "  Skipped $($_.ADName) - Blank IPPhone field."
      }
     
      Write-KSLog "Input duplicate checking"
      
      # Duplicate element testing (by ADName)
      $Entries | Where-Object { -not $_.Result } | Group-Object ADName | Where-Object Count -gt 1 | ForEach-Object {
        $Duplicate = $false

        $First = $_.Group[0] | ConvertTo-Csv | Select-Object -Last 1
        $_.Group[1..($_.Count - 1)] | ForEach-Object {
          if (($_ | ConvertTo-Csv | Select-Object -Last 1) -ne $First) {
            # Unreconcilable duplicate
            $Duplicate = $true
          } else {
            # Tentatively mark this as a simple duplicate line (identical to a previous line)
            $_.Result = "Skipped"; $_.KPMGComment = "Repeated entry."
            Write-KSLog "  Skipped: $($_.ADName) - Repeated (tentative)" -LogLevel Warning
          }
        }
          
        if ($Duplicate) {
          $_.Group | ForEach-Object {
            $_.Result = "Skipped"; $_.KPMGComment = "Unequal repeated entry (cannot reconcile automatically)."
            Write-KSLog "  Skipped: $($_.ADName) - Repeated (cannot reconcile)" -LogLevel Warning
          }
        }
      }

      # Duplicate element testing (by IPPhone)
      $Entries | Where-Object { -not $_.Result } | Group-Object IPPhone | Where-Object Count -gt 1 | Select-Object -ExpandProperty Group | ForEach-Object {
        $_.Result = "Skipped"; $_.KPMGComment = "IPPhone assigned to multiple users in this spreadsheet."
        Write-KSLog "  Skipped: $($_.ADName) IPPhone assigned to multiple users in this spreadsheet."
      }
      
      # Prepare a list of all users which are likely to be modified in this session.
      $ModifiedAccounts = @{}
      $Entries | Where-Object { -not $_.Result } | ForEach-Object { $ModifiedAccounts.Add($_.ADName, "") }
      
      #
      # Active Directory checking
      #
      
      Write-KSLog "Checking users against Active Directory"
      
      $Entries | Where-Object { -not $_.Result } | ForEach-Object {
        Write-KSLog "User: $($_.ADName)"
      
        $KSADUser = Get-KSADUser -SamAccountName $_.ADName
        
        if ($KSADUser -and ([Array]$KSADUser).Count -eq 1) {
          $_.KSADUser = $KSADUser

          if ($KSADUser.IPPhone -and $KSADUser.IPPhone -eq $_.IPPhone) {
            $_.Result = "Skipped"; $_.KPMGComment = "No change to existing number."
            $_.TelephoneNumber = $KSADUser.TelephoneNumber
            $_.OtherTelephone = $KSADUser.OtherTelephone
            Write-KSLog "  Skipped: $($_.KPMGComment)"
          } else {
            # Numbers can be reassigned if they are in the current block (and no errors have been detected), or if the user account in AD is marked as Separated (4) in AD from SAP
            $ExistingNumber = Get-KSADUser -Enabled -IPPhone $_.IPPhone -LdapFilter "(!kPMG-User-GOEmployeeStatus=4)" | Where-Object { -not ($ModifiedAccounts.Contains($_.SamAccountName)) }
            
            if ($ExistingNumber) {
              $_.Result = "Failed"; $_.KPMGComment = "IPPhone is already assigned to active user(s): $(($ExistingNumber | Select-Object -ExpandProperty SamAccountName) -join ', ')."
              Write-KSLog "  Failed: $($_.KPMGComment)"
            }

            if ($KSADUser.AccountIsDisabled) {
              $_.KPMGComment = "Active Directory account is disabled."
              $_.Result = "Warning"
              Write-KSLog "  Failed: $($_.KPMGComment)"
            }
            
            if ($KSADUser.givenName -eq $null -or $KSADUser.sn -eq $null) {
              $_.KPMGComment = "First or last name is blank in Active Directory. Call Manager import will fail for this user."
              $_.Result = "Warning"
              Write-KSLog "  Blank first or last name. First name: $($KSADUser.givenName); Last name: $($KSADUser.sn)" -LogLevel Warning
            }
          }
        } else {
          [Array]$MatchingAccounts = Get-KSADUser -givenName $_.FirstName -sn $_.LastName -physicalDeliveryOfficeName $_.Office
          if (-not $MatchingAccounts) {
            [Array]$MatchingAccounts = Get-KSADUser -givenName $_.FirstName -sn $_.LastName
          }

          $_.KPMGComment = switch ($MatchingAccounts.Count) {
            0       { "Could not find Active Directory account."; break }
            1       { "Could not find Active Directory account. ADName suggestion - $($MatchingAccounts[0].SamAccountName)"; break }
            default { "Could not find Active Directory account. Too matches for $($_.FirstName) $($_.LastName)." }
          }

          $_.Result = "Failed"
          Write-KSLog "  Failed: $($_.KPMGComment)"
        }
        
        if (-not $_.Result) {
          Write-KSLog "  Passed all Active Directory checks"
        }
      }
      
      #
      # Commit changes
      #

      Write-KSLog "Committing changes"
      
      $Entries | Where-Object { -not $_.Result -or $_.Result -eq 'Warning' } | ForEach-Object {
        Write-KSLog "User: $($_.KSADUser.UserPrincipalName)"
        $Entry = $_

        if ($psboundparameters.ContainsKey("WhatIf")) {
          $ModifiedEntry = $Entry.KSADUser | Set-KSADTelephoneNumber -IPPhone $Entry.IPPhone -WhatIf
          $Entry.TelephoneNumber = $ModifiedEntry.TelephoneNumber
          $Entry.OtherTelephone = $ModifiedEntry.OtherTelephone
        } else {
          $ModifiedEntry = $Entry.KSADUser | Set-KSADTelephoneNumber -IPPhone $Entry.IPPhone
          $Entry.TelephoneNumber = $ModifiedEntry.TelephoneNumber
          $Entry.OtherTelephone = $ModifiedEntry.OtherTelephone
        }
        if ($?) {
          # Preserve the warning flag.
          if ($Entry.Result -ne "Warning") {
            $Entry.Result = "Success"
          }
          
          if (Test-Path "$FolderName\History\History.csv") {
            $ModifiedEntry | Select-Object @{n='TimeStamp';e={ $TimeStamp }}, * | ConvertTo-Csv | Select-Object -Last 1 | Out-File "$FolderName\History\History.csv" -Append
          } else {
            $ModifiedEntry | Select-Object @{n='TimeStamp';e={ $TimeStamp }}, * | Export-Csv "$FolderName\History\History.csv" -NoTypeInformation
          }
          
          if ($Entry.KSADUser.distinguishedName -match 'OU=KRC,OU=Function,DC=uk,DC=kworld,DC=kpmg,DC=com$') {
            $Entry.LyncResult = "Skipped"; $Entry.LyncComment = "KGS user"
          } else {
            if ($Entry.KSADUser."msRTCSIP-UserEnabled") {
              $Entry.LyncResult = "Success"
              
              if (-not $psboundparameters.ContainsKey("WhatIf")) {
                if ($LyncSessionImported) {
                  $CSUser = Get-CsUser -Identity $KSADUser.UserPrincipalName 
                
                  try {
                    Set-CsUser -Identity $Entry.KSADUser.UserPrincipalName -RemoteCallControlTelephonyEnabled $true `
                      -LineServerURI "sip:$($Entry.ADName)@UKNLBCUP001.uk.kworld.kpmg.com" `
                      -LineURI "tel:$($Entry.IPPhone)`;phone-context=dialstring" `
                      -ErrorAction Stop
                  } catch {
                    $Entry.LyncResult = "Failed"; $Entry.LyncComment = "$($_.Exception.Message.Trim())"
                  }
                } else {
                  $Entry.LyncResult = "Failed"; $Entry.LyncComment = "Lync management session import failed."
                }
              }
            } else {
              $Entry.LyncResult = "Failed"; $Entry.LyncComment = "Account not Lync enabled."
            }
          }
        }
      }
      
      $Entries | Where-Object { $_.Result -in 'Skipped', 'Failed' } | ForEach-Object {
        $_.LyncResult = "Skipped"
      }

      #
      # Reporting
      #

      # Sort the results
      $Entries = $Entries | Sort-Object {
        switch -regex ("$($_.KPMGComment) $($_.Result)") { 
          "Failed"             { 1; break }
          "Warning"            { 2; break }
          "No change.+Skipped" { 5; break }
          "Skipped"            { 3; break }
          "Success"            { 4; break } 
          default              { 4 }
        }
      }, ADName

      #
      # PreContent
      #
      
      $PreContent = "<p class='LargeFont'><b>$(($Entries | Measure-Object).Count) account(s) processed. Please check highlighted failed or skipped entries in the table below (Result column).</b></p>"
      
      #
      # PostContent
      #
      
      $PostContent = @()

      $DuplicateAssignmentUsers = $Entries | Where-Object { $_.Result -match 'Failed' -and $_.KPMGComment -match 'already assigned' } | ForEach-Object {
        ($_.KPMGComment -replace '^[^:]+: ') -split ' *,' | ForEach-Object { $_.TrimEnd('.') }
      } | Select-Object -Unique | Sort-Object
      if ($DuplicateAssignmentUsers) {
        $PostContent += "<p>The following information is supplied to help debug duplicate number assignment. Numbers may be manually re-assigned if the existing user has left.</p>"
      
        $PostContent += $DuplicateAssignmentUsers | ForEach-Object {
          Get-KSADUser -SamAccountName $_ -Properties accountExpires, SamAccountName, givenName, sn, ipPhone, userAccountControl, 'kpmg-user-goemployeestatus', description, lastLogonTimeStamp | Select-Object `
            @{n='ADName';e={ $_.SamAccountName }},
            @{n='FirstName';e={ $_.givenName }},
            @{n='LastName';e={ $_.sn }},
            IPPhone, AccountIsDisabled, AccountIsExpired, 
            @{n='SAPStatus';e={ $_.'kpmg-user-goemployeestatus' }}, Description, @{n='LastLogon';e={ $_.lastLogonTimeStamp }}
        } | ConvertTo-Html -Fragment
      }
      
      $LogPath = Get-KSSetting KSGlobalLogPath -ExpandValue
      $LogFile = Get-KSLog -Name $myinvocation.InvocationName | Select-Object -ExpandProperty LogFile
      if ($LogPath) {
        $LogFile = Join-Path $LogPath (Split-Path $LogFile -Leaf)
      }
      $PostContent += "<p class='SmallGrey'>Detailed logging is available in $LogFile</p>"
      
      $HtmlDocument = $Entries | Select-Object * -ExcludeProperty KSADUser | ConvertTo-Html -PreContent $PreContent -Head (Get-KSTextResource HtmlHead) -PostContent $PostContent | ForEach-Object {
        $HtmlLine = $_
        switch -regex ($HtmlLine) {
          '<td>Failed'  { $HtmlLine = $HtmlLine -replace '<td>Failed([^<]*)', '<td class="Red">Failed$1' }
          '<td>Warning' { $HtmlLine = $HtmlLine -replace '<td>Warning([^<]*)', '<td class="Orange">Warning$1' }
          '<td>Success' { $HtmlLine = $HtmlLine -replace '<td>Success([^<]*)', '<td class="WhiteFontGreen"><b>Success$1</b>' }
          '<td>Skipped' { $HtmlLine = $HtmlLine -replace '(?<!<td(?: class="[^"]+")?>(?:Failed|Skipped|No change to existing number).+)<td>Skipped([^<]*)', '<td class="Orange">Skipped$1' }
        }
        $HtmlLine
      } | Out-String
      
      $BTHtmlDocument = $Entries | Select-Object * -ExcludeProperty TelephoneNumber, OtherTelephone, LyncComment, LyncResult, KSADUser | ConvertTo-Html -PreContent $PreContent -Head (Get-KSTextResource HtmlHead) | ForEach-Object {
        $HtmlLine = $_
        switch -regex ($HtmlLine) {
          '<td>Failed'  { $HtmlLine = $HtmlLine -replace '<td>Failed([^<]*)', '<td class="Red">Failed$1' }
          '<td>Success' { $HtmlLine = $HtmlLine -replace '<td>Success([^<]*)', '<td class="WhiteFontGreen"><b>Success$1</b>' }
          '<td>Skipped' { $HtmlLine = $HtmlLine -replace '(?<!<td(?: class="[^"]+")?>(?:Failed|Skipped|No change to existing number).+)<td>Skipped([^<]*)', '<td class="Orange">Skipped$1' }
        }
        $HtmlLine
      } | Out-String
      
      if ($psboundparameters.ContainsKey("WhatIf")) {
        Write-KSLog "Sending mail to KSAdministrators"
        Send-MailMessage -From (Get-KSSetting KSUsersEmail -ExpandValue) -To (Get-KSSetting KSAdministratorsEmail -ExpandValue) -Subject "KScript: AD Flags Report (Internal) - $FileDate" -Body $HtmlDocument -BodyAsHtml
        Send-MailMessage -From (Get-KSSetting KSUsersEmail -ExpandValue) -To (Get-KSSetting KSAdministratorsEmail -ExpandValue) -Subject "KScript: AD Flags Report (BT) - $FileDate" -Body $BTHtmlDocument -BodyAsHtml
      } else {
        # Mail to BT
        Write-KSLog "Sending mail to BT"
        Send-MailMessage -From (Get-KSSetting KSUsersEmail -ExpandValue) -To "kpmg.smac@bt.com" -Subject "KScript: AD Flags Report (BT) - $FileDate" -Body $BTHtmlDocument -BodyAsHtml

        # Mail to Core Tech and Unified Communications
        Write-KSLog "Sending mail to Core Technologies and Unified Communications"
        Send-MailMessage -From (Get-KSSetting KSUsersEmail -ExpandValue) -To (Get-KSSetting KSUsersEmail -ExpandValue), "UK-DLITSUnifiedCommunicationsTeam@kpmg.co.uk" -Subject "KScript: AD Flags Report (Internal) - $FileDate" -Body $HtmlDocument -BodyAsHtml
      }
    }
    
    Move-Item $_.FullName "$FolderName\ProcessedFiles\$($_.Name)" -Force
    if (-not $? -and (Test-Path "$FolderName\ProcessedFiles\$($_.Name)")) {
      Remove-Item "$FolderName\ProcessedFiles\$($_.Name)"
    }
  }
  
  if (-not $FileDate) {
    Write-KSLog "No files to process"
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}