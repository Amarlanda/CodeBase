

"" | Select-Object one, two, three

New-PsObject -Property ([Ordered]@{
  one = 1;
  two = 2;
})



$Properties = "one", "two", "three"
Get-VM | Select-Object $Properties





$HashTable = @{}
"One, two, three".Split(", ") | ForEach-Object {
  
}