    $IPAddress = "10.11.12.13"

  [System.Net.IPAddress]::Parse($IPAddress)

    $Bytes

    $Bytes = [array]::Reverse($Bytes)
    
    $rev = $Bytes -join '.'

    $rev
