function Set-KSSignature {
  # .SYNOPSIS
  #   A wrapper function for Set-AuthenticodeSignature.
  # .DESCRIPTION
  #   Set-KSSignature uses Set-AuthenticodeSignature to sign script.
  #
  #   The code signing certificate is automatically selected from the current user certificate store.
  # .PARAMETER Path
  #   The path to the file to sign, accepts pipeline input from Get-ChildItem.
  # .EXAMPLE
  #   Set-KSSignature -Path FileName.ps1
  # .EXAMPLE
  #   Get-ChildItem C:\Scripts | Set-KSSignature
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     19/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias("FullName")]
    [String]$Path
  )

  begin {
    $Certificate = Get-ChildItem cert:\CurrentUser\My | 
      Where-Object {
        $_.HasPrivateKey -and
        $_.NotBefore -le (Get-Date) -and
        $_.NotAfter -ge (Get-Date) -and
        ($_.Extensions | 
          Where-Object { ($_.EnhancedKeyUsages | 
            ForEach-Object { $_.FriendlyName }) -contains 'Code Signing' }) }
  }

  process {
    if ($Certificate -and $Path -match '(ps1|psm1|ps1xml)$') {
      Set-AuthenticodeSignature $Path -Certificate $Certificate
    }
  }
}