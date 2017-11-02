#More detials here
#https://stackoverflow.com/questions/34166023/powershell-modify-elements-of-array

$myArray = 1,2,3,4,5
$myArray = $myArray |ForEach-Object {
  $_ *= 10
  $_
}

$myArray