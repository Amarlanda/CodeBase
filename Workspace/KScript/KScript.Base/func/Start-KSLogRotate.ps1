function Start-KSLogRotate {
  # .SYNOPSIS
  #   Start rotating log files.
  # .DESCRIPTION
  #   Start-KSLogRotate is a simple log rotate function which executes against the content of the folder referenced by the KSLogPath setting.
  #
  #   Log files must use the extension .log. Archive files must use the extension .zip.
  #
  #   Start-KSLogRotate performs the following actions:
  #
  #     1. Find all log files in KSLogPath, KSReportPath and KSTranscriptLogPath (if each is defined).
  #     2. If the last write time is before today (midnight) minus KSLogAgeLimit days, Compress (zip) the log file into a monthly file.
  #     3. Find all log archive files in KSLogPath.
  #     4. If the last write time is before today (midnight) minus KSLogArchiveAgeLimit days, delete the log archive file.
  #
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/08/2014 - Chris Dent - Added logging.
  #     07/08/2014 - Chris Dent - Modified to handle all current log paths (KSLogPath, KSReportPath, KSTranscriptLogPath).
  #     15/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param( )
  
  Write-KSLog "Started $($myinvocation.InvocationName)" -StartTranscript
  
  "KSLogPath", "KSReportPath", "KSTranscriptLogPath" | ForEach-Object {
    Write-KSLog "Rotating $_"
  
    $Path = Get-KSSetting $_ -ExpandValue
    
    if ($Path -and (Test-Path $Path -PathType Container)) {
    
      $LogAgeLimitSetting = Get-KSSetting KSLogAgeLimit -ExpandValue
      if ($LogAgeLimitSetting) {
        $LogAgeLimit = New-TimeSpan -Days $LogAgeLimitSetting
      } else {
        Write-KSLog "Using default log age limit of 7 days." -LogLevel Warning
        $LogAgeLimit = New-TimeSpan -Days 7
      }
    
      $ArchiveAgeLimitSetting = Get-KSSetting KSLogArchiveAgeLimit -ExpandValue
      if ($ArchiveAgeLimitSetting) {
        $ArchiveAgeLimit = New-TimeSpan -Days $ArchiveAgeLimitSetting
      } else {
        Write-KSLog "Using default archive age limit of 185 days." -LogLevel Warning
        $ArchiveAgeLimit = New-TimeSpan -Days 185
      }

      Get-ChildItem $Path -File |
        Where-Object { $_.Extension -in '.log', '.txt', '.html' -and $_.LastWriteTime -lt ((Get-Date).Date - $LogAgeLimit) } |
        ForEach-Object {
          Write-KSLog "File: $($_.FullName)"
        
          Write-KSLog "  Adding to $($_.FullName -replace '\d{2}\.\w{3,4}$', '.zip')."
          Compress-KSItem $_.FullName -ArchiveName ($_.FullName -replace '\d{2}\.\w{3,4}$', '.zip')

          Write-KSLog "  Removing file."
          Remove-Item $_.FullName
        }
      
      # Purge expired archive files
      Get-ChildItem $LogPath -Filter *.zip -File |
        Where-Object { $_.LastWriteTime -lt ((Get-Date).Date - $ArchiveAgeLimit) } |
        ForEach-Object {
          Write-KSLog "File: $($_.FullName)"
          Write-KSLog "  Removing file."
          Remove-Item $_.FullName
        }
    }
  }
  
  Write-KSLog "Finished $($myinvocation.InvocationName)" -StopTranscript
}