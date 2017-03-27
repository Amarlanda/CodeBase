function New-KSDynamicModuleBuilder {
  # .SYNOPSIS
  #   Creates a new assembly and a dynamic module within the current AppDomain.
  # .DESCRIPTION
  #   Prepares a System.Reflection.Emit.ModuleBuilder class to allow construction of dynamic types. The ModuleBuilder is created to allow the creation of multiple types under a single assembly.
  # .PARAMETER AssemblyName
  #   A name for the in-memory assembly.
  # .PARAMETER UseGlobalVariable
  #   By default, this function stores the requested ModuleBuilder in a global variable called KS_ModuleBuilder. This leaves the ModuleBuilder object accessible to New-KSEnum without needing an explicit assignment operation.
  # .INPUTS
  #   System.Reflection.AssemblyName
  # .OUTPUTS
  #   System.Reflection.Emit.ModuleBuilder
  # .EXAMPLE
  #   New-KSDynamicModuleBuilder "Example.Assembly"
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
  #     11/06/2014 - Chris Dent - Forked from source module.
  
  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true)]
    [Reflection.AssemblyName]$AssemblyName,
    
    [Boolean]$UseGlobalVariable = $true,
    
    [Switch]$PassThru
  )
  
  $AppDomain = [AppDomain]::CurrentDomain

  # Multiple assemblies of the same name can exist. This check aborts if the assembly name exists on the assumption
  # that this is undesirable.
  $AssemblyRegEx = "^$($AssemblyName.Name -replace '\.', '\.'),"
  if ($AppDomain.GetAssemblies() |
    Where-Object { 
      $_.IsDynamic -and $_.Fullname -match $AssemblyRegEx }) {

    Write-Error "New-KSDynamicModuleBuilder: Dynamic assembly $($AssemblyName.Name) already exists."
    return
  }
  
  # Create a dynamic assembly in the current AppDomain
  $AssemblyBuilder = $AppDomain.DefineDynamicAssembly(
    $AssemblyName, 
    [Reflection.Emit.AssemblyBuilderAccess]::Run
  )

  $ModuleBuilder = $AssemblyBuilder.DefineDynamicModule($AssemblyName.Name)
  if ($UseGlobalVariable) {
    # Create a transient dynamic module within the new assembly
    New-Variable KS_ModuleBuilder -Scope Global -Value $ModuleBuilder
    if ($PassThru) {
      $ModuleBuilder
    }
  } else {
    return $ModuleBuilder
  }
}