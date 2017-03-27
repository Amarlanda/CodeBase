New-Variable -Name PrivateKeyFile -Scope Script -Value $Null -Force

function Import-SshKey {
  # .SYNOPSIS
  #   Allows a key to be loaded without storing the passphrase in a variable (transient use only)
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     30/10/2014 - Chris Dent - First release.

  param(
    [Parameter(Mandatory = $True)]
    [ValidateScript( { Test-Path $_ } )]
    [String]$File,

    [Parameter()]
    [ValidateRange(1, 10)]
    [Int32]$MaxRetries = 3
  )

  try { $Script:PrivateKeyFile = New-Object Renci.SshNet.PrivateKeyFile($File) } catch { }
  if (!$PrivateKeyFile) {
  
    # Need an error handler here - need to allow multiple password attempts
    $i = 0
    do {
      $i++
      try { 
        $Script:PrivateKeyFile = New-Object Renci.SshNet.PrivateKeyFile(
          $File,
          [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR((Read-Host "Passphrase" -AsSecureString)))
        )
      } catch { }
      $KeyLoaded = $?

      if (!$KeyLoaded -and $i -lt $MaxRetries) {
        Write-Host "Invalid pass-phrase, please retry" -ForegroundColor Red
      } elseif (!$KeyLoaded -and $i -eq $MaxRetries) {
        Write-Host "Invalid pass-phrase. Too many retries." -ForegroundColor Red
      }
    } until ($KeyLoaded -or $i -eq $MaxRetries)
  }
}