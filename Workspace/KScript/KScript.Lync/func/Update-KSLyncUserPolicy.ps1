function Update-KSLyncUserPolicy {
  # .SYNOPSIS
  #   Update Lync users in accordance with policies defined by Get-KSLyncPolicy.
  # .DESCRIPTION
  #   Update-KSLyncUserPolicy assembles filters, finds users, then executes the commands defined in policy on each matching user.
  #
  #   Update-KSLyncUserPolicy relies on policy content read by Get-KSLyncPolicy.
  # .EXAMPLE
  #   Update-KSLyncUserPolicy
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/08/2014 - Chris Dent - First release.
 
  [CmdLetBinding(SupportsShouldProcess = $true)]
  param( )

  Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript
  
  Get-KSLyncPolicy | ForEach-Object {
    Write-KSLog "Reading policy $($_.Name)"
  
    $SearchExpression = GetKSLyncPolicySearchExpression -KSLyncPolicy $_ -UserPrincipalName $UserPrincipalName
    $Parameters = $SearchExpression.Parameters
    
    Write-KSLog "Applying policy $($_.Name)"
    Write-KSLog "  LdapFilter: $($Parameters['LdapFilter'])"
    if ($Parameters.Contains("OU")) {
      Write-KSLog "  OU:         $($Parameters['OU'])"
    }
    Write-KSLog "  Where:      $($SearchExpression.WhereStatement)"

    $Commands = $_.Commands
    Get-CsAdUser @Parameters | Where-Object $SearchExpression.WhereStatement | ForEach-Object {
      Write-KSLog "User: $($_.UserPrincipalName)"
      
      $DN = $_.DistinguishedName

      $Commands -split "`n" | ForEach-Object {
        $Command = $_
        
        Write-KSLog "  Command: $Command"

        try {
          if ($pscmdlet.ShouldProcess("Executing $Command for $DN")) {
            $CsUser = Get-CsUser -Identity $DN
            if ($CsUser) {
              $Error.Clear()
              Invoke-Expression $Command
              if ($Error) {
                Write-KSLog "  Command failed: $Command :: $($Error[0].Exception.Message)" -LogLevel Error
              }
            }
          }
        } catch {
          Write-KSLog "  Command failed: $Command :: $($_.Exception.Message)" -LogLevel Error
        }
      }
    }
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}