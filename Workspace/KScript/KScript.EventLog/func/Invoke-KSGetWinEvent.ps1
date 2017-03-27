function Invoke-KSGetWinEvent {
  # .SYNOPSIS
  #   Invoke-KSGetWinEvent wraps around Get-WinEvent.
  # .DESCRIPTION
  #   Invoke-KSGetWinEvent provides a wrapper for Get-WinEvent to resolve a bug which prevents several fields returning when run in cultures other than en-US.
  #
  #   Invoke-KSGetWinEvent continually switches culture to ensure display formats are consistent with the current culture.
  #
  #   For usage, refer to documentation for Get-WinEvent.
  # .NOTES
  #   Author: Chris Dent
  #   Team:   Core Technologies
  #
  #   Change log:
  #     17/06/2014 - Chris Dent - First release
  
  [CmdLetBinding(DefaultParameterSetName = 'GetLogSet')]
  param( )
  
  dynamicparam {
    $ParamDictionary = New-Object Management.Automation.RuntimeDefinedParameterDictionary

    Get-KSCommandParameters Get-WinEvent | ForEach-Object {
      $DynamicParameter = New-Object Management.Automation.RuntimeDefinedParameter($_.Name, $_.ParameterType, $_.Attributes)
      $ParamDictionary.Add($_.Name, $DynamicParameter)
    }
    
    return $ParamDictionary
  }
  
  begin {
    # Store the current culture.
    $CurrentCulture = [Threading.Thread]::CurrentThread.CurrentCulture

    # Execute Get-WinEvent as en-US
    [Threading.Thread]::CurrentThread.CurrentCulture = "en-US"
    Get-WinEvent @psboundparameters | ForEach-Object { 
      # Reset the culture to display output (important for fields based on DateTime)
      [Threading.Thread]::CurrentThread.CurrentCulture = $CurrentCulture
      $_
      # Allow processing to continue using en-US
      [Threading.Thread]::CurrentThread.CurrentCulture = "en-US"
    }
    # Put the culture back to the original
    [Threading.Thread]::CurrentThread.CurrentCulture = $CurrentCulture
  }
}