function New-KSStruct {
  # .SYNOPSIS
  #   Creates a new struct from a hashtable using an existing dynamic module.
  # .DESCRIPTION
  #   New-KSStruct dynamically creates an struct with the specified name (and namespace).
  #
  #   A hashtable is used to populate the struct.
  # 
  #   The struct is created, but not returned by this function.
  # .PARAMETER Members
  #   A hashtable describing the members of the struct. The hashtable will contain the property name as a key and the property type as the value. If marshalling of the return value is required the type may be passed as an array where the second element is the unmanaged type (see examples).
  # .PARAMETER ModuleBuilder
  #   A dynamic module within a dynamic assembly, created by New-KSDynamicModuleBuilder. By default, the function uses the global variable KS_ModuleBuilder, populated if New-DynamicModuleBuilder is executed with UseGlobalVariable set to true (the default value).
  # .PARAMETER Name
  #   A name for the struct, a namespace may be included.
  # .INPUTS
  #   System.Reflection.Emit.ModuleBuilder
  #   System.String
  #   System.HashTable
  # .EXAMPLE
  #   C:\PS>New-KSDynamicModuleBuilder "Example"
  #
  #   Creates a new enumeration in memory, then returns values "dog" and "rabbit".
  # .EXAMPLE
  #   C:\PS>$Builder = New-KSDynamicModuleBuilder "Example" -UseGlobalVariable $false
  #
  #   Uses a user-defined variable to store the created dynamic module. The example returns the value "two".
  # .EXAMPLE
  #   C:\PS>New-KSDynamicModuleBuilder "Example"
  #
  #   Multiple Enumerations can be built within the same dynamic assembly, a module builder only needs to be created once.
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
  #     16/01/2015 - Chris Dent - First release.
  
  [CmdLetBinding()]
  param(
    [Reflection.Emit.ModuleBuilder]$ModuleBuilder = $KS_ModuleBuilder,

    [Parameter(Mandatory = $true, Position = 1)]
    [ValidatePattern('^(\w+\.)*\w+$')]
    [String]$Name,
   
    [Runtime.InteropServices.LayoutKind]$LayoutKind = [Runtime.InteropServices.LayoutKind]::Sequential,
    
    [Runtime.InteropServices.CharSet]$CharacterSet,
    
    [Parameter(Mandatory = $true)]
    [HashTable]$Members
  )
  
  # This function cannot overwrite or append to existing types. 
  # Abort if a type of the same name is found and return a more friendly error than ValidateScript would.
  if ($Name -as [Type]) {
    Write-Error "New-KSStruct: Type $Name already exists"
    return
  }
 
  $TypeBuilder = $ModuleBuilder.DefineType(
    $Name,
    [Reflection.TypeAttributes]"Public, SequentialLayout")
  if ($?) {
    if ($psboundparameters.ContainsKey("CharacterSet")) {
      $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(
        [Runtime.InteropServices.StructLayoutAttribute].GetConstructor([Runtime.InteropServices.LayoutKind]),
        @($LayoutKind),
        [Runtime.InteropServices.StructLayoutAttribute].GetField('CharSet'),
        @($CharacterSet)
      )
    } else {
      $CustomAttribute = New-Object Reflection.Emit.CustomAttributeBuilder(
        [Runtime.InteropServices.StructLayoutAttribute].GetConstructor([Runtime.InteropServices.LayoutKind]),
        @($LayoutKind)
      )
    }
    $TypeBuilder.SetCustomAttribute($CustomAttribute)

    $Members.Keys | ForEach-Object {
      if ($Members[$_] -is [Array]) {
        $FieldBuilder = $TypeBuilder.DefineField($_, [Type]$Members[$_][0], [Reflection.FieldAttributes]::Public)
        $FieldBuilder.SetMarshal([Reflection.Emit.UnmanagedMarshal]::DefineUnmanagedMarshal($Members[$_][1]))
      } else {
        $FieldBuilder = $TypeBuilder.DefineField($_, [Type]$Members[$_], [Reflection.FieldAttributes]::Public)
      }
    }
    $Struct = $TypeBuilder.CreateType()
  }
}


$Builder = New-KSDynamicModuleBuilder "Test" -UseGlobalVariable $false
New-KSStruct -ModuleBuilder $Builder -Name "Test.Struct1" -Members @{
  "One" = [Int32];
  "Two" = [IntPtr];
}
New-KSStruct -ModuleBuilder $Builder -Name "Test.Struct2" -CharacterSet 'Auto' -Members @{
  "One" = [Int32];
  "Two" = [IntPtr];
  "Three" = @([String], [Runtime.InteropServices.UnmanagedType]::LPWStr)
}
 