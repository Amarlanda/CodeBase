function Get-KSVMSnapshot {
  # .SYNOPSIS
  #   Get VM snapshots from SCVMM.
  # .DESCRIPTION
  #   Get-KSVMSnapshot is built to request VMCheckPoints from SCVMM.
  #
  #   Each Snapshot is tagged with a simple type based on the description and creation date.
  #
  #   The description is loosely parsed, it looks for the following keywords:
  #
  #     * After Migration
  #     * App Migration
  #     * Application Migration
  #     * Post Migration
  #
  #   If any of the combinations above are present the snapshot is tagged as "AppMigration".
  #
  #   If a description is not set, but the snapshot was created within 24 hours of the VM it is tagged as DayOne.
  #
  #   If all tests above fail the snapshot will be tagged as BAU (Business As Usual).
  # .INPUTS
  #   System.String
  # .OUTPUTS
  #   KScript.VirtualInfrastructure.Snapshot
  # .EXAMPLE
  #   Get-KSVMSnapshot
  #
  #   Get all snapshots for all VMs.
  # .EXAMPLE
  #   Get-KSVMSnapshot -Name SomeVirtualMachine
  #
  #   Get snapshots associated with SomeVirtualMachine.
  # .EXAMPLE
  #   Get-KSVMSnapshot -SnapshotType "AppMigration"
  #
  #   Get all snapshots tagged as being created for AppMigration.
  # .EXAMPLE
  #   Get-KSVMSnapshot -SnapshotType "AppMigration", "DayOne"
  #
  #   Get all snapshots tagged as being created for AppMigration or DayOne.
  # .EXAMPLE
  #   Get-Content AListOfVMs.txt | Get-KSVMSnapshot -SnapshotType "AppMigration", "DayOne" | Remove-SCVMCheckpoint
  #
  #   Get all AppMigration and DayOne snapshots associated with the list of virtual machines in AListOfVMs.txt. Immediately remove each of the snapshots.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     30/07/2014 - Chris Dent - First release.

  [CmdLetBinding()]
  param(
    [Parameter(ValueFromPipeline = $true)]
    [Alias('VM')]
    [String]$Name,
    
    [ValidateSet('AppMigration', 'DayOne', 'BAU')]
    [String[]]$SnapshotType = ('AppMigration', 'DayOne', 'BAU')
  )

  begin {
    $VIServers = Import-Csv "$psscriptroot\..\var\vi-entities.csv" | Where-Object { $_.Type -in 'SCVMM' -and $_.Description -eq 'SP1' }
  }
  
  process {
    if ($VIServers -and (Get-Module virtualmachinemanager)) {
      $VIServers | ForEach-Object {
        Get-SCVMMServer $_.Name | Out-Null
     
        $Params = @{}
        if ($psboundparameters.ContainsKey("Name")) { $Params.Add("VM", $Name) }
     
        Get-SCVMCheckpoint @Params | Group-Object VM | ForEach-Object {
          $VMCreationTime = Get-SCVirtualMachine -Name $_.Name | Select-Object -ExpandProperty CreationTime
          
          $_.Group | ForEach-Object {
            $VMSnapshot = $_ |
              Add-Member VMCreationTime -MemberType Noteproperty -Value $VMCreationTime -PassThru -Force |
              Add-Member SnapshotType -MemberType ScriptProperty -PassThru -Force -Value {
                if ($this.Description -match '^(?:Post|After|App(?:lication)?) Migration') {
                  "AppMigration"
                } elseif (($this.AddedTime - $this.VMCreationTime) -lt (New-TimeSpan -Days 1)) {
                  "DayOne"
                } else {
                  "BAU"
                }
              }
            $VMSnapshot.PSObject.TypeNames.Add("KScript.VirtualInfrastructure.Snapshot")
            
            $VMSnapshot
          }
        } | Where-Object { $_.SnapshotType -in $SnapshotType }
      }
    }
  }
}