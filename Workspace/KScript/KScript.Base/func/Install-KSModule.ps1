function Install-KSModule {
  # .SYNOPSIS
  #   Installs or updates KScript.* modules.
  # .DESCRIPTION
  #   Install-KSModule attempts to download and install modules from the path set by Set-KSSourcePath
  #
  #   Install-KSModule may be used to download modules for the first time, to upgrade existing modules, or to re-install a module.
  # .PARAMETER Force
  #   By default Install-KSModule takes no action if the current version of a module is installed. Setting the Force parameter allows re-installation of modules with the same (or greater) version number.
  # .PARAMETER ModuleDescription
  #   The required ModuleDescription object is returned using Get-KSModule, Install-KSModule accepts pipeline input from Get-KSModule.
  # .PARAMETER ModulePath
  #   By default modules are installed into the first path in the PSModulePath environmental variable. This behaviour can be changed by supplying a value for ModulePath.
  #
  #   If a module is already installed this parameter will be ignored, an attempt will be made to update the module in its current location.
  # .PARAMETER Name
  #   A module name beginning with "KScript.", such as KScript.AD. Using Name as a parameter causes a call-back to Get-KSModule.
  # .INPUTS
  #   KScript.Module.Description
  #   System.String
  # .EXAMPLE
  #   Get-KSModule | Install-KSModule
  #
  #   Get and install all available modules.
  # .EXAMPLE
  #   Get-KSModule Indented.Common | Install-KSModule
  # 
  #   Get a named module then install or upgrade.
  # .EXAMPLE
  #   Install-KSModule Indented.Dns
  #
  #   Install-KSModule executes the search, then installs or upgrades as appropriate.
  # .LINK
  #   http://www.indented.co.uk/indented-common/
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #   Module: Indented.Common
  #
  #   (c) 2008-2014 Chris Dent.
  #
  #   Permission to use, copy, modify, and/or distribute this software for any purpose with or without fee is hereby granted, 
  #   provided that the above copyright notice and this permission notice appear in all copies.
  #
  #   THE SOFTWARE IS PROVIDED “AS IS” AND THE AUTHOR DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED 
  #   WARRANTIES OF MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY SPECIAL, DIRECT, INDIRECT, OR 
  #   CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF 
  #   CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
  #
  #   Change log:
  #     07/08/2014 - Chris Dent - BugFix: Settings preservation under KScript.Base.
  #     10/07/2014 - Chris Dent - Fixed settings write-back.
  #     04/07/2014 - Chris Dent - Modified to read settings using Get-KSSetting.
  #     24/06/2014 - Chris Dent - Fix for robocopy commands.
  #     20/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding(SupportsShouldProcess = $true, DefaultParameterSetName = 'ModuleDescription')]
  param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true, ParameterSetName = 'ModuleDescription')]
    [ValidateScript( { $_.PsObject.TypeNames -contains 'KScript.Module.Description' } )]
    $ModuleDescription,

    [Parameter(Mandatory = $true, Position = 1, ParameterSetName = 'Name')]
    [ValidatePattern('^KScript\.\w+$')]
    [String]$Name,
    
    [ValidateScript( { Test-Path $_ } )]
    [Alias('Path')]
    [String]$ModulePath = (($env:PsModulePath -split ';')[0]),
    
    [Switch]$Force
  )
  
  begin {
    if ($pscmdlet.ParameterSetName -eq 'Name') {
      # Call back to Get-KSModule to get the information we need.
      Get-KSModule $Name | Install-KSModule -ModulePath $ModulePath
    }
  }
  
  process {
    if ($ModuleDescription) {
      if ($ModuleDescription.Path) {
        $ModulePath = $ModuleDescription.Path -replace "\\$($ModuleDescription.Name)\\.+$"
      }
    
      if ($ModuleDescription.LocalVersion -eq 'Not installed') {
        $Install = $true
      } elseif ($ModuleDescription.ServerVersion -gt $ModuleDescription.LocalVersion -or $Force) {
        $Install = $true
      }
      
      $InstallSource = Get-KSSetting KSModuleUpdatePath -ExpandValue
      
      if ($Install -and (Test-Path $InstallSource)) {
        if ($pscmdlet.ShouldProcess("Installing $($ModuleDescription.Name) to $ModulePath")) {
          # If updating KScript.Base save the local settings.
          if ($ModuleDescription.Name -eq 'KScript.Base') {
            $Settings = Get-KSSetting -LocalOnly
          }
        
          robocopy "$InstallSource\$($ModuleDescription.Name)" "$ModulePath\$($ModuleDescription.Name)" /MIR
         
          # Restore the local settings.
          if ($ModuleDescription.Name -eq 'KScript.Base') {
            $Settings | Set-KSSetting
          }
         
          if (Get-Module $ModuleDescription.Name -ListAvailable) {
            Write-Verbose "Install-KSModule: Module $($ModuleDescription.Name) installed and imported successfully."
          }
        }
      } else {
        Write-Verbose "Install-KSModule: Module $($ModuleDescription.Name) is up to date."
      }
    }
  }
}