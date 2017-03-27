function Test-KSTrustedCertificate {
  # .SYNOPSIS
  #   Test for a certificate in the TrustedPeople store on the target computer.
  # .DESCRIPTION
  #   Test-KSTrustedCertificate attempts to find a matching certificate in the TrustedPeople store.
  # .PARAMETER Certificate
  #   The certificate to test.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Test-KSTrustedCertificate uses the current computer.
  # .PARAMETER Detail
  #   Test-KSTrustedCertificate returns a boolean (true or false) value by default. The result of all tests performed may be returned as an object by specifying the Detail parameter.
  # .PARAMETER StoreLocation
  #   Test-KSTrustedCertificate gets certificates from the LocalMachine store. The CurrentUser store may be specified.
  # .INPUTS
  #   System.Security.Cryptography.X509Certificates.StoreLocation
  #   System.Security.Cryptography.X509Certificates.X509Certificate2
  #   System.String
  # .OUTPUTS
  #   System.Boolean
  # .EXAMPLE
  #   $Certificate = Get-KSCertificate -StoreName My -ComputerName Server1
  #   Test-KSTrustedCertificate $Certificate -ComputerName Server2
  #
  #   Returns true if a matching public key from $Certificate is installed into the trusted store on Server2.
  # .NOTES
  #   Author: Chris Dent
  #   Team: Core Technologies
  #
  #   Change log:
  #     12/06/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
    
    [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

    [String]$ComputerName = $env:ComputerName,
    
    [Switch]$Detail
  )
  
  $MatchingCertificates = Get-KSCertificate -StoreName TrustedPeople -ComputerName $ComputerName |
    Where-Object { $_.FriendlyName -eq $Certificate.FriendlyName } |
    ForEach-Object {
      $Status = "Valid"
      if ($_.NotBefore -gt (Get-Date)) {
        $Status = "Not valid yet"
      }
      if ($_.NotAfter -lt (Get-Date)) {
        $Status = "Expired"
      }
      if ($_ -ne $Certificate) {
        $Status = "Friendly name match only"
      }
      $_ | Add-Member Status -MemberType NoteProperty -Value $Status -PassThru
    }
    
  if ($Detail) {
    return $MatchingCertificates
  }
  if ($MatchingCertificates | Where-Object Status -eq 'Valid') {
    return $true
  } else {
    return $false
  }
}