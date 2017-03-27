function Get-KSTextResource {
  # .SYNOPSIS
  #   Get text-based shared resources.
  # .DESCRIPTION
  #   Gets text-based resources from a published resource path.
  # .PARAMETER Name
  #   The name of the resource to get.
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   System.String
  # .EXAMPLE
  #   Get-KSTextResource HtmlHead
  #
  #   Get a specific resource.
  # .EXAMPLE
  #   Get-KSTextResource -List
  #
  #   List available resources.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     07/07/2014 - Chris Dent - First release.
  
  [CmdLetBinding(DefaultParameterSetName = 'ByName')]
  param(
    [Parameter(Position = 1, ParameterSetName = 'ByName')]
    [ValidateNotNullOrEmpty()]
    [String]$Name = "*",
    
    [Parameter(ParameterSetName = 'List')]
    [Switch]$List
  )

  $ResourcePath = Get-KSSetting KSTextResourcePath -ExpandValue
  
  if (Test-Path $ResourcePath -PathType Container) {
    $Resources = Get-ChildItem $ResourcePath | Where-Object { $_.BaseName -like $Name }
    
    if (([Array]$Resources).Count -gt 1 -or $List) {
      return ($Resources | Select-Object -ExpandProperty BaseName)
    } else {
      return (Get-Content $Resources.FullName -Raw)
    }
  } else {
    Write-Warning "Get-KSTextResource: Path does not exist or is not accessible."
  }
}