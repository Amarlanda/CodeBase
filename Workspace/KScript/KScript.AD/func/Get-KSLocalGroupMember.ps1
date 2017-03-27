function Get-KSLocalGroupMember {
  # .SYNOPSIS
  #   Get all members of a local group.
  # .DESCRIPTION
  #   Get-KSLocalGroupMember connects to a local group and gets all members.
  # .PARAMETER DirectoryEntry
  #   A directory entry, typically created by Get-KSLocalGroup, representing a connection to the group.
  # .INPUTS
  #   System.DirectoryServices.DirectoryEntry
  #   System.String
  # .OUTPUTS
  #   KScript.Local.Object
  # .EXAMPLE
  #   Get-KSLocalGroup SomeGroup | Get-KSLocalGroupMember
  # .EXAMPLE
  #   Get-KSLocalGroup Administrators -ComputerName SomeComputer | Get-KSLocalGroupMember
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     29/10/2014 - Chris Dent - BugFix: COM interoperability bug when this command is not called from the runspace. Unable to bind or address local objects returned by the Member method.
  #     25/09/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
    [ValidateNotNullOrEmpty()]
    [DirectoryServices.DirectoryEntry]$DirectoryEntry
  )

  process {
    if ($DirectoryEntry.Class -eq 'group') {
      $DirectoryEntry.Members() | ForEach-Object {
        $MemberDirectoryEntry = [DirectoryServices.DirectoryEntry]$_
        
        try { $MemberDirectoryEntry.Properties.Keys | Out-Null } catch { }
        if (-not $?) {
          # Work around obscure COM interoperability problems by attempting to re-bind to the object. Best effort only.
          $MemberDirectoryEntry = NewKSADDirectoryEntry -DirectoryPath $MemberDirectoryEntry.Path
        }
        
        $Object = $MemberDirectoryEntry.Properties | ConvertFromKSADPropertyCollection -ObjectPath $MemberDirectoryEntry.Path -ObjectType $MemberDirectoryEntry.Class
        $Object.PSObject.TypeNames.Add("KScript.Local.Object")
        
        # Property: DirectoryEntry
        $Object | Add-Member DirectoryEntry -MemberType NoteProperty -Value $MemberDirectoryEntry
        
        $Object
      }
    }
  }
}
