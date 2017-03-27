function Import-KSADAttributeConverter {
  # .SYNOPSIS
  #   Import the script at the specified path into the current module.
  # .DESCRIPTION
  #   Import-KSADAttributeConverter records references to parameter conversion scripts.
  #
  #   The following restrictions apply:
  #
  #     * If code signing is enforced, the converter script must be signed.
  #     * The type name cannot be an existing .NET type.
  #
  # .PARAMETER ImportAsFunction
  #   By default scripts are called whenever the type is referenced. Alternatively the file can be can be imported into Script scope as a function (with the same name as the Type).
  # .PARAMETER Path
  #   The path to the file to load.
  # .PARAMETER Type
  #   A type name may be specified if the file name differs. By default the file name (without extension) is used as the type.
  # .INPUTS
  #   System.String
  # .EXAMPLE
  #   Import-KSADAttributeConverter C:\Converters\LargeIntegerDate.ps1
  # .EXAMPLE
  #   Import-KSADAttributeConverter -Path c:\temp\Script.ps1 -Type LargeIntegerDate
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     13/06/2014 - Chris Dent - First release  
 
  [CmdletBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateScript( { Test-Path $_ } )]
    [Alias('FullName')]
    [String]$Path,
    
    [String]$Type,
    
    [Switch]$ImportAsFunction
  )

  begin {
    if (-not $Script:ADAttributeConverters) {
      New-Variable ADAttributeConverters -Value @{} -Scope Script
    }
  }

  process {
    if (-not $Type) {
      $Type = (Get-Item $Path).BaseName
    }
    if ($Type -as [Type]) {
      Write-Error "Cannot override .NET type." -Category InvalidArgument
      return
    }
  
    if ($Script:ADAttributeConverters[$Type]) {
      Write-Error "A converter is already loaded for this type ($Type)." -Category InvalidArgument
      return
    }
    
    if ($ImportAsFunction) {
      $Definition = @("function Script:$Type {")
      $Definition += Get-Content $Path | ForEach-Object { "  $_" }
      $Definition += "}"
      
      $Definition = $Definition | Out-String

      Invoke-Expression $Definition
    }

    $Script:ADAttributeConverters.Add($Type, $Path)
  }
}