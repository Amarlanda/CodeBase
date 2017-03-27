function Install-KSCertificate {
  # .SYNOPSIS
  #   Install a certificate.
  # .DESCRIPTION
  #   Install a certificate in the specified store.
  # .PARAMETER Certificate
  #   The certificate to install.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSCertificate uses the current computer.
  # .PARAMETER StoreLocation
  #   Install-KSCertificate installs certificates into the LocalMachine store. The CurrentUser store may be specified.
  # .PARAMETER StoreName
  #   Install-KSCertificate installs certificates into the TrustedPeople store. A specific store name may be supplied if required.
  # .INPUTS
  #   System.Security.Cryptography.X509Certificates.X509Certificate2
  #   System.Security.Cryptography.X509Certificates.StoreName
  #   System.Security.Cryptography.X509Certificates.StoreLocation
  #   System.String
  # .EXAMPLE
  #   $Certificate = Get-KSCertificate -StoreName My -ComputerName Server1
  #   Install-KSCertificate $Certificate -ComputerName Server2
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     12/06/2014 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [Security.Cryptography.X509Certificates.X509Certificate2]$Certificate,
    
    [Security.Cryptography.X509Certificates.StoreName]$StoreName = "TrustedPeople",
    
    [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",

    [String]$ComputerName = $env:ComputerName
  )

  $Store = New-Object Security.Cryptography.X509Certificates.X509Store("\\$ComputerName\$_", $StoreLocation)
  try {
    $Store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadWrite)
  } catch {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      $_.Exception.InnerException,
      "Exception",
      [Management.Automation.ErrorCategory]::OpenError,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
  
  try {
    $Store.Add($Certificate)
  } catch {
    $ErrorRecord = New-Object Management.Automation.ErrorRecord(
      $_.Exception.InnerException,
      "Exception",
      [Management.Automation.ErrorCategory]::WriteError,
      $pscmdlet)
    $pscmdlet.ThrowTerminatingError($ErrorRecord)
  }
  
  $Store.Close()
}