function Get-KSCertificate {
  # .SYNOPSIS
  #   Get certificates from a local or remote certificate store.
  # .DESCRIPTION
  #   Get X509 certificates from a certificate store.
  # .PARAMETER ComputerName
  #   An optional ComputerName to use for this query. If ComputerName is not specified Get-KSCertificate uses the current computer.
  # .PARAMETER Expired
  #   Filter results to only include expired certificates.
  # .PARAMETER HasPrivateKey
  #   Filter results to only include certificates which have a private key available.
  # .PARAMETER StoreLocation
  #   Get-KSCertificate gets certificates from the LocalMachine store. The CurrentUser store may be specified.
  # .PARAMETER StoreName
  #   Get-KSCertificate gets certificates from all stores. A specific store name, or list of store names, may be supplied if required.
  # .INPUTS
  #   System.Security.Cryptography.X509Certificates.StoreName
  #   System.Security.Cryptography.X509Certificates.StoreLocation
  #   System.String
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     24/06/2014 - Chris Dent - Added HasPrivateKey and Expired parameters.
  #     12/06/2014 - Chris Dent - First release.  
  
  [CmdLetBinding()]
  param(
    [Security.Cryptography.X509Certificates.StoreName[]]$StoreName = [Enum]::GetNames([Security.Cryptography.X509Certificates.StoreName]),

    [Security.Cryptography.X509Certificates.StoreLocation]$StoreLocation = "LocalMachine",
  
    [Parameter(ValueFromPipelineByPropertyName = $true)]
    [Alias('ComputerNameString', 'Name')]
    [String]$ComputerName = $env:ComputerName,
    
    [Switch]$HasPrivateKey,
    
    [Switch]$Expired
  )

  begin {
    $WhereStatementText = '$_'
    if ($HasPrivateKey) {
      $WhereStatementText = $WhereStatementText + ' -and $_.HasPrivateKey'
    }
    if ($Expired) {
      $WhereStatementText = $WhereStatementText + ' -and $_.NotAfter -lt (Get-Date)'
    }
    $WhereStatement = [ScriptBlock]::Create($WhereStatementText)
  }
  
  process {
    $StoreName | ForEach-Object {
      $StorePath = "$StoreLocation\$_"
    
      $Store = New-Object Security.Cryptography.X509Certificates.X509Store("\\$ComputerName\$_", $StoreLocation)
      $Store.Open([Security.Cryptography.X509Certificates.OpenFlags]::ReadOnly)
      
      if ($?) {
        $Store.Certificates |
          Add-Member StorePath -MemberType NoteProperty -Value $StorePath -PassThru |
          Add-Member ComputerName -MemberType NoteProperty -Value $ComputerName -PassThru |
          Where-Object $WhereStatement
        
        $Store.Close()
      }
    }
  }
}