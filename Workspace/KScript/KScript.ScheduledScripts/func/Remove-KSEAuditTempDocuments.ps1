function Remove-KSEAuditTempDocuments {
  # .SYNOPSIS
  #   Remove files over 14 days old from \\uknasdata400\TempDocuments.
  # .DESCRIPTION
  #   Remove-EAuditTempDocuments deletes files over 14 days old from \\uknasdata400\TempDocuments.
  #
  #   Service owner:   Steve Geraghty / Patrick Forrester (eAudit support)
  #   PREMAS number:   
  #   Service account: uk-svc-auto-eaudit
  #   Schedule:        Daily, 1am.
  #
  # .NOTES
  #   Author:    Chris Dent
  #   Team:      Core Technologies
  #   Requestor: Patrick Forrester / Steve Geraghty
  #
  #   Change log:
  #     13/11/2014 - Chris Dent - Merged into KScript.ScheduledScripts for version and release control.
  #     30/10/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param( )

  Write-KSLog "Starting $($myinvocation.MyCommand)" -StartTranscript

  Get-ChildItem \\uknasdata400\TempDocuments -File -Recurse | 
    Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-14) } | 
    ForEach-Object {
      Write-KSLog "Removing $($_.FullName) ($($_.LastWriteTime.ToString('u')))"
      Remove-Item $_.FullName
    }

  Write-KSLog "Finished $($myinvocation.MyCommand)" -StopTranscript
}