# Disable CRL checking

$RegPath = 'Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing'
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -Name State -Value 146944

# Compile VMWare XmlSerializers (if not already done)
# 5.8 pre-compiles these during installation.

if ((Get-PSSnapIn VMWare.VimAutomation.Core -Registered).Version -lt [Version]"5.8") {
  $VMWareXmlSerializers = "VimService50.XmlSerializers, Version=5.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService41.XmlSerializers, Version=4.1.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService40.XmlSerializers, Version=4.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService25.XmlSerializers, Version=2.5.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService50.XmlSerializers, Version=5.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService41.XmlSerializers, Version=4.1.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService40.XmlSerializers, Version=4.0.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f",
                          "VimService25.XmlSerializers, Version=2.5.0.0, Culture=neutral, PublicKeyToken=10980b081e887e9f"

  $VMWareXmlSerializers |
    Where-Object { -not (Test-Path "$env:SystemRoot\Assembly\GAC_MSIL\$($_ -replace ',.+$')") } |
    ForEach-Object {
      Write-Host "Installing VMWare XmlSerializer (one-time only): $($_ -replace ',.+$')"

      if (Test-Path "$env:SystemRoot\Microsoft.NET\Framework64\v2.0.50727\ngen.exe") {
        & "$env:SystemRoot\Microsoft.NET\Framework64\v2.0.50727\ngen.exe" "install", $_
      }
      if (Test-Path "$env:SystemRoot\Microsoft.NET\Framework\v2.0.50727\ngen.exe") {
        & "$env:SystemRoot\Microsoft.NET\Framework\v2.0.50727\ngen.exe" "install", $_
      }
    }
}

# Import VMWare VSphere

if (Get-PSSnapIn VMWare.VimAutomation.Core -Registered -ErrorAction SilentlyContinue) {
  Add-PSSnapIn VMWare.VimAutomation.Core
  
  Set-PowerCliConfiguration -InvalidCertificateAction Ignore -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
}

# Import SCVMM CmdLets

if (Get-Module virtualmachinemanager -ListAvailable) {
  Import-Module virtualmachinemanager
  
  Remove-Item alias:Get-VM
  Remove-Item alias:Get-VMHost
  Remove-Item alias:Get-Job
}

# Import failoverclusters CmdLets

if (Get-Module failoverclusters -ListAvailable) {
  Import-Module failoverclusters
}
