#
# Module manifest for module 'KScript.EventLog'
#
# Generated by: Chris Dent
#
# Generated on: 12/11/2014
#

@{

# Script module or binary module file associated with this manifest.
RootModule = 'KScript.EventLog'

# Version number of this module.
ModuleVersion = '1.55'

# ID used to uniquely identify this module
GUID = 'b73385ee-e6e4-43b2-9c27-e441ad66ee65'

# Author of this module
Author = 'Chris Dent'

# Company or vendor of this module
CompanyName = 'KPMG'

# Copyright statement for this module
Copyright = '(c) 2014 KPMG. All rights reserved.'

# Description of the functionality provided by this module
Description = '<module><description>Event log query tools.</description><type>ToolSet</type></module>'

# Minimum version of the Windows PowerShell engine required by this module
PowerShellVersion = '3.0'

# Name of the Windows PowerShell host required by this module
# PowerShellHostName = ''

# Minimum version of the Windows PowerShell host required by this module
# PowerShellHostVersion = ''

# Minimum version of Microsoft .NET Framework required by this module
# DotNetFrameworkVersion = ''

# Minimum version of the common language runtime (CLR) required by this module
# CLRVersion = ''

# Processor architecture (None, X86, Amd64) required by this module
# ProcessorArchitecture = ''

# Modules that must be imported into the global environment prior to importing this module
RequiredModules = @('KScript.AD')

# Assemblies that must be loaded prior to importing this module
# RequiredAssemblies = @()

# Script files (.ps1) that are run in the caller's environment prior to importing this module.
# ScriptsToProcess = @()

# Type files (.ps1xml) to be loaded when importing this module
# TypesToProcess = @()

# Format files (.ps1xml) to be loaded when importing this module
FormatsToProcess = 'KScript.EventLog.Format.ps1xml'

# Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
# NestedModules = @()

# Functions to export from this module
FunctionsToExport = '*-*'

# Cmdlets to export from this module
CmdletsToExport = '*'

# Variables to export from this module
VariablesToExport = '*'

# Aliases to export from this module
AliasesToExport = '*'

# List of all modules packaged with this module
# ModuleList = @()

# List of all files packaged with this module
FileList = 'KScript.EventLog.psd1', 'KScript.EventLog.psm1', 
               'func\Get-KSUnexpectedReboot.ps1', 'func\Invoke-KSGetWinEvent.ps1'

# Private data to pass to the module specified in RootModule/ModuleToProcess
# PrivateData = ''

# HelpInfo URI of this module
# HelpInfoURI = ''

# Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
# DefaultCommandPrefix = ''

}

