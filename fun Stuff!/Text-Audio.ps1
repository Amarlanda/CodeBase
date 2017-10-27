$text = 'Hello World'

$sapi =New-Object -ComObject Sapi.spvoice
$null = $sapi.speak($text)