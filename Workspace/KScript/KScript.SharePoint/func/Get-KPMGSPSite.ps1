function Get-KPMGSPSite {
  # .SYNOPSIS
  #   Get an SharePoint 2007 site object.
  # .DESCRIPTION
  #   Get-KPMGSPSite is used to create and manage persistent web service connections to a SharePoint 2007 site.
  # .PARAMETER SPSite
  #   The URI for the SharePoint site.
  # .PARAMETER PassThru
  #   Get-KPMGSPSite stores the connection object in a persistent variable accessible by KPMG_SPSite.
  # .INPUTS
  #   System.URI
  # .OUTPUTS
  #   KPMG.SharePoint.Site
  # .EXAMPLE
  #   Get-KPMGSPSite "http://server/sites/the-site"

  [CmdLetBinding()]
  param(
    [Parameter()]
    [URI]$SPSite = "http://sites.eu.kworld.kpmg.com/sites/infrastructure/department/itservices/ServerBuild/",
    
    [Switch]$PassThru
  )

  if ($Script:KPMG_SPSite) {
    return $Script:KPMG_SPSite
  }
  
  $SPSiteObject = New-Object PSObject -Property ([Ordered]@{
    SiteURI = $SPSite
  })
  
  GetKPMGSPInterface | ForEach-Object {
    $InterfaceName = $_.Name
  
    $Interface = New-Object PSObject -Property ([Ordered]@{
      Name       = $InterfaceName
      ServiceURI = "$($SPSite.AbsoluteUri)$((GetKPMGSPInterface Lists).URL)?WSDL"
      Service    = $null
      Connected  = $false
    })
    
    # Method: Connect
    $Interface | Add-Member Connect -MemberType ScriptMethod -Value {
      param(
        [PSCredential]$Credential
      )
      
      $Params = @{}
      if ($Credential) {
        $Params.Add("Credential", $Credential)
      } else {
        $Params.Add("UseDefaultCredential", $true)
      }
      
      try {
        $this.Service = New-WebServiceProxy -URI $this.ServiceURI -Namespace SpWd @Params
      } catch {
      
      }
      if ($?) { $this.Connected = $true }
    }
    # Method: ToString
    $Interface | Add-Member ToString -MemberType ScriptMethod -Force -Value {
      return "Connected: $($this.Connected)"
    }
    
    # Property (SPSite): Interface
    $SPSiteObject | Add-Member $InterfaceName -MemberType NoteProperty -Value $Interface
  }
  
  $Script:KPMG_SPSite = $SPSiteObject
  return $Script:KPMG_SPSite
}