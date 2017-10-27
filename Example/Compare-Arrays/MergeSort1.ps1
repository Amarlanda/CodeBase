param ( $theArray = @() )

$global:counter = 0

# Merges two sorted halves of a subarray
# $theArray is an array of comparable objects
# $tempArray is an array to place the merged result
# $leftPos is the left-most index of the subarray
# $rightPos is the index of the start of the second half
# $rightEnd is the right-most index of the subarray
function merge($theArray, $tempArray, [int] $leftPos, [int] $rightPos, [int] $rightEnd)
{
  $leftEnd = $rightPos - 1
  $tmpPos = $leftPos
  $numElements = $rightEnd - $leftPos + 1
	
  # Main loop
  while (($leftPos -le $leftEnd) -and ($rightPos -le $rightEnd))
  {
    $global:counter++
    if ($theArray[$leftPos].CompareTo($theArray[$rightPos]) -le 0)
    {
      $tempArray[$tmpPos++] = $theArray[$leftPos++]
    }
    else
    {
      $tempArray[$tmpPos++] = $theArray[$rightPos++]
    }
  }
	
  while ($leftPos -le $leftEnd)
  {
    $tempArray[$tmpPos++] = $theArray[$leftPos++]
  }
	
  while ($rightPos -le $rightEnd)
  {
    $tempArray[$tmpPos++] = $theArray[$rightPos++]
  }
	
  # Copy $tempArray back
  for ($i = 0; $i -lt $numElements; $i++, $rightEnd--)
  {
    $theArray[$rightEnd] = $tempArray[$rightEnd]
  }
}

# Makes recursive calls
# $theArray is an array of comparable objects
# $tempArray is an array to place the merged result
# $left is the left-most index of the subarray
# $right is the right-most index of the subarray
function mergesorter( $theArray, $tempArray, [int] $left, [int] $right )
{
  if ($left -lt $right)
  {
    [int] $center = [Math]::Floor(($left + $right) / 2)
    mergesorter $theArray $tempArray $left $center
    mergesorter $theArray $tempArray ($center + 1) $right
    merge $theArray $tempArray $left ($center + 1) $right
  }
}

$tempArray = New-Object Object[] $theArray.Count
mergesorter $theArray $tempArray 0 ($theArray.Count - 1)

Write-Host "Array items: `t" $theArray.Count
Write-Host "Iterations: `t" $global:counter


