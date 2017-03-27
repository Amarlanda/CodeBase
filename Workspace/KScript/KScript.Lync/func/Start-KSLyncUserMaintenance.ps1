function Start-KSLyncUserMaintenance {
  # .SYNOPSIS
  #   Start the Enable-KSLyncUser command.
  # .DESCRIPTION
  #   Start-KSLyncUserMaintenance is a reporting wrapper for a number of scripts, each is run in order:
  #
  #     * Disable-KSLyncUser - Removes AD-disabled accounts from the Lync system.
  #     * Enable-KSLyncUser - Adds recently created users to the Lync system.
  #
  #   Start-KSLyncUserMaintenance provides extensive reporting for Enable-KSLyncUser. The command output is converted to HTML and sent as an e-mail message.
  #
  #   Start-KSLyncUserMaintenance inherits parameters from Enable-KSLyncUser and passes all bound parameters through without modification.
  # .EXAMPLE
  #   Start-KSLyncUserMaintenance
  # .EXAMPLE
  #   Start-KSLyncUserMaintenance -WhatIf
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  # 
  #   Change log:
  #     07/08/2014 - Chris Dent - Added transcript logging option.
  #     29/07/2014 - Chris Dent - Increased wait time between disable and enable operations.
  #     24/07/2014 - Chris Dent - Title change.
  #     23/07/2014 - Chris Dent - Formatting changes, bug fixes, added support for Get-KSSMTPConfiguration.
  #     22/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(SupportsShouldProcess = $true)]
  param( )
  
  dynamicparam {
    $ParamDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary

    Get-KSCommandParameters Enable-KSLyncUser | ForEach-Object {
      $DynamicParameter = New-Object Management.Automation.RuntimeDefinedParameter($_.Name, $_.ParameterType, $_.Attributes)
      $ParamDictionary.Add($_.Name, $DynamicParameter)
    }
    
    return $ParamDictionary
  }
  
  begin {
    Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript
  
    if ($psboundparameters.ContainsKey("WhatIf")) {
      Disable-KSLyncUser -WhatIf 
    } else {
      Disable-KSLyncUser
    }
    
    Write-KSLog "Waiting 20 minutes for replication"
    Start-Sleep -Seconds 1200

    $NewLyncUsers = Enable-KSLyncUser @psboundparameters | Sort-Object DisplayName
    
    Write-KSLog "Generating report"
    
    $DisplayProperties = "UserName", "DisplayName", "WhenCreated", "RegistrarPool", "SipAddress", "Result", @{n='KGS Lync Policies Applied';e={ $_.PostEnableCommandStatus }}
    $AllUsers = $NewLyncUsers | Select-Object $DisplayProperties
    
    # Flag users which have been set up using a manually defined SIP address
    $ManualSIPAddressUsers = $NewLyncUsers | Where-Object { $_.EnableType -eq 'ManualSIPAddress' } | Select-Object $DisplayProperties
    $AutomaticSIPAddressUsers = $NewLyncUsers | Where-object { $_.EnableType -eq 'AutomaticSIPAddress' } | Select-Object $DisplayProperties
    
    $PreContent = @("<h1><u>JML New Users: Enable Lync User Report</u></h1>")
    
    if ($psboundparameters.ContainsKey("WhatIf")) {
      $PreContent += "<p class='LargeFontRed'><b>WhatIf is set, no changes have been made.</b></p>"
    }
    
    $PreContent += "<p class='LargeFont'><b>$(($AllUsers | Measure-Object).Count) account(s) found. Please check the tables below and remediate any failed or skipped accounts (see Result and KGS Lync Policies Applied column).</b></p>"
    
    if ($ManualSIPAddressUsers) {
      $PreContent += "<p class='LargeFont'><b>Non-<i>kpmg.co.uk</i> email addresses found on new AD user accounts.</b> These accounts have been Lync enabled with <i>kpmg.co.uk</i> SIP addresses. See action required below:</p>"
      $PreContent += "<p class='LargeFontRed'><b>Verify that these accounts should have a <i>kpmg.co.uk</i> SIP address.</b></p>"
      $PreContent += $ManualSIPAddressUsers | ConvertTo-Html -Fragment | Out-String
    } else {
      $PreContent += "<p class='LargeFont'>No non-kpmg.co.uk email addresses found on new AD user accounts. See action required below:</p>"
      $PreContent += "<p class='LargeFontGreen'><b>No action required.</b></p>"
    }
   
    if ($AutomaticSIPAddressUsers) {
      $PreContent += "<p class='LargeFont'><b>Account(s) created using primary <i>kpmg.co.uk</i> email address as SIP address (KPMG default):</p>"
    }
    
    $LogPath = Get-KSSetting KSGlobalLogPath -ExpandValue
    $LogFile = Get-KSLog -Name $myinvocation.InvocationName | Select-Object -ExpandProperty LogFile
    if ($LogPath) {
      $LogFile = Join-Path $LogPath (Split-Path $LogFile -Leaf)
    }
    $PostContent = "<p class='SmallGrey'>Detailed logging is available in $LogFile</p>"
    
    $HtmlBody = $AutomaticSIPAddressUsers | ConvertTo-Html -PreContent $PreContent -Head (Get-KSTextResource -Name HtmlHead) -PostContent $PostContent
    $HtmlBody = $HtmlBody | ForEach-Object {
      switch -regex ($_) {
        '<td>Failed'  { $_ -replace '<td>', '<td class="Red">'; break }
        '<td>Skipped' { $_ -replace '<td>', '<td class="Orange">'; break }
        default       { $_ -replace '<td>OK([^<]*)', '<td class="WhiteFontGreen"><b>OK$1</b>' }
      }
    }
    
    # Clear out empty tables (can occur if $AutomaticSIPAddressUsers is $null which is used to build the HTML document)
    $HtmlBody = ($HtmlBody | Out-String) -replace '<table>[\r\n]+</table>'
    
    # Get report configuration for this function.
    $SmtpConfiguration = Get-KSSMTPConfiguration -Name $myinvocation.InvocationName
    
    if ($SmtpConfiguration) {
      if ($psboundparameters.ContainsKey("WhatIf")) {
        $SmtpConfiguration.Subject = "Test: $($SmtpConfiguration.Subject)"
      }

      Send-MailMessage -To $SmtpConfiguration.Recipients -From $SmtpConfiguration.Sender `
        -Body $HtmlBody -BodyAsHtml -Subject $SmtpConfiguration.Subject -ErrorAction SilentlyContinue -ErrorVariable SmtpError

      if ($?) {
        Write-KSLog "Sent report message"
      } else {
        Write-KSLog "Send-MailMessage: $($SmtpError.Exception.Message)"
      }
    } else {
      Write-KSLog "SMTP configuration not set or not available."
    }
    
    Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
  }
}
