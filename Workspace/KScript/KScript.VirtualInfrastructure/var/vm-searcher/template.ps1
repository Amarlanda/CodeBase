function GetKSSampleTypeVM {
  [CmdLetBinding()]
  param(
    $Name,
  
    $Id,
    
    $VIEntity
  )

  GetSampleTypeVM | ForEach-Object {
    New-Object PSObject -Property ([Ordered]@{
      Name     = <NameProperty>
      Host     = <HostProperty>
      Type     = "SampleType"
      VIEntity = <VIEntity>
      State    = <NormalisedPowerState>
      Id       = <PlatformSpecificUniqueId>
    })
  }
}