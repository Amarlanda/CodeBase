function Get-KPMGSPItem {
  #

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [Alias("Name")]
    [String]$ListName,
  
    [PSCredential]$Credential
  )

  begin {
    $Params = @{}
    if ($Credential) {
      $Params.Add("Credential", $Credential)
    } else {
      $Params.Add("UseDefaultCredential", $true)
    }

    $ServiceURI = "$($SPSite.AbsoluteUri)$((GetKPMGSPInterface Lists).URL)?WSDL"
    
    Write-Host $ServiceURI
    
    $WebService = New-WebServiceProxy -URI $ServiceURI -Namespace SpWd @Params
  }
  
  process {
    if ($WebService) {
      $WebService.GetListItems($ListName, $null, $null, $null, 1000, $null, $null).data.row | ForEach-Object {
        $Item = New-Object PSObject -Property ([Ordered]@{
          Name     = $_.ows_FileLeafRef -replace '^[^#]+#'
          URI      = [URI]($_.ows_FileRef -replace '^[^#]+#', "$($SPSite.Scheme)://$($SPSite.Authority)/")
          Author   = $_.ows_Author -replace '^[^#]+#'
          Editor   = $_.ows_Editor -replace '^[^#]+#'
          UniqueId = [Guid]($_.ows_UniqueId -replace '^[^#]+#')
          Created  = Get-Date ($_.ows_Created_x0020_Date -replace '^[^#]+#')
          Modified = Get-Date $_.ows_Modified
          Site     = $SPSite
        })
        $Item.PsObject.TypeNames.Add("KPMG.SharePoint.Item")
        
        $Item
      }
    }
  }
}