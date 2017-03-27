function Get-KPMGSPList {
  # .SYNOPSIS
  #   Get SharePoint lists from a SharePoint 2007 site.
  # .DESCRIPTION
  #   Get all lists from a KPMG site.
  # 
  
  
  [CmdLetBinding()]
  param(
    [String]$ListName,
    
    [PSCredential]$Credential
  )
  
  if (-not $Script:KPMG_SPSite) {
    # Exit here.
  } else {
    if (-not $Script:KPMG_SPSite.Lists.Connected) {
      $Script:KPMG_SPSite.Lists.Connect()
    }
    $Service = $Script:KPMG_SPSite.Lists.Service
  }
  
  if ($ListName) {
    $Lists = $WebService.GetList($ListName)
  } else {
    $Lists = $WebService.GetListCollection().List
  }
  
  $Lists | ForEach-Object {
    $List = New-Object PSObject -Property ([Ordered]@{
      Name           = $_.Title
      Description    = $_.Description
      ItemCount      = $_.ItemCount
      UniqueId       = [Guid]($_.ID -replace '^[^#]+#')
      URI            = [URI]"$($SPSite.Scheme)://$($SPSite.Authority)/$($_.WebFullUrl)"
      DocTemplateURI = [URI]"$($SPSite.Scheme)://$($SPSite.Authority)/$($_.DocTemplateUrl)"
      DefaultViewURI = [URI]"$($SPSite.Scheme)://$($SPSite.Authority)/$($_.DefaultViewUrl)"
      Created        = [DateTime]::ParseExact($_.Created, "yyyyMMdd hh:mm:ss", [Globalization.CultureInfo]::CurrentCulture)
      Modified       = [DateTime]::ParseExact($_.Modified, "yyyyMMdd hh:mm:ss", [Globalization.CultureInfo]::CurrentCulture)
      Site           = $SPSite
    })
    $List.PsObject.TypeNames.Add("KPMG.SharePoint.List")
    
    $List
  }
}