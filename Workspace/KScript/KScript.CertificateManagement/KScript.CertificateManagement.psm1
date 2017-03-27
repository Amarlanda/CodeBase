#
# Module loader for KScript.CertificateManagement
#

# Public functions
$Public = 'Get-KSCertificate',
          'Install-KSCertificate',
          'Test-KSTrustedCertificate'

$Public | ForEach-Object {
  Import-Module "$psscriptroot\func\$_.ps1"
}