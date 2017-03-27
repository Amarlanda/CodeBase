function Get-KSSCOMClosedMonitorState {
  [CmdLetBinding()]
  param(
    [String]$Name = "*"
  )
  
  $Criteria = "IsMonitorAlert = 'TRUE' AND ResolutionState = 255 AND ResolvedBy <> 'System' AND ResolvedBy <> 'Auto-resolve' AND ResolvedBy <> 'Maintenance Mode'"
  
  # Replace * and ? for SQL style wildcards.
  if ($Name -match '\*|\?') {
    $Name = $Name -replace '\*', '%'
    $Name = $Name -replace '\?', '_'
    $Criteria = "$Criteria AND PrincipalName LIKE '$Name'"
  } else {
    $Criteria = "$Criteria AND PrincipalName = '$Name'"
  }
  
  Get-SCOMAlert -Criteria $Criteria | ForEach-Object {
  
    $MonitoringObject = Get-SCOMMonitoringObject -Id $_.MonitoringObjectId
    $Monitor = Get-SCOMMonitor -Id $_.MonitoringRuleId
    
    # Construct the list required by the GetMonitoringStates method
    $MonitorList = New-Object Collections.Generic.List[Microsoft.EnterpriseManagement.Configuration.ManagementPackMonitor]
    $MonitorList.Add($Monitor)
    
    # Get the current state of the monitor
    $MonitorState = $MonitoringObject.GetMonitoringStates($MonitorList)
  
    New-Object PSObject -Property ([Ordered]@{
      PrincipalName               = $_.PrincipalName
      AlertName                   = $_.Name
      AlertResolutionState        = (Get-SCOMAlertResolutionState -ResolutionStateCode $_.ResolutionState).Name
      MonitoringObjectName        = $MonitoringObject.DisplayName
      MonitoringObjectHealthState = $MonitoringObject.HealthState
      MonitoringObjectId          = $_.MonitoringObjectId
      MonitorDisplayName          = $MonitorState.MonitorDisplayName
      MonitorHealthState          = $MonitorState.HealthState
      MonitorId                   = $_.MonitoringRuleId
      ResolvedBy                  = $_.ResolvedBy
    })
  } | Where-Object { $_.MonitorHealthState -notin 'Success', 'Uninitialized' }
}


Get-KSSCOMClosedMonitorState